import 'package:flutter/material.dart';
import 'backend_ffi.dart';
import 'stem_player.dart';
import 'model_downloader.dart';
import 'model_download_dialog.dart';
import 'history_service.dart';
import 'history_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:just_audio_media_kit/just_audio_media_kit.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  JustAudioMediaKit.ensureInitialized();
  runApp(const MyApp());
}

class ProgressTracker {
  final DateTime _startTime = DateTime.now();

  String? calculateEta(double progress) {
    if (progress <= 0 || progress >= 1.0) return null;
    final elapsed = DateTime.now().difference(_startTime);
    final total = elapsed.inMilliseconds / progress;
    final remaining = Duration(milliseconds: (total - elapsed.inMilliseconds).toInt());

    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Stemmer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'YouTube Stemmer',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isProcessing = false;
  String? _stemsDirectory;
  String? _videoTitle;
  List<String>? _stemNames;
  Map<String, String>? _stemFiles;

  double _downloadProgress = 0;
  double _stemmingProgress = 0;
  String? _downloadEta;
  String? _stemmingEta;

  AppModel _selectedModel = availableModels.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModel(_selectedModel);
    });
  }

  Future<bool> _checkModel(AppModel model) async {
    final downloader = ModelDownloader();
    if (!await downloader.isModelDownloaded(model)) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ModelDownloadDialog(model: model),
        );
        return result == true;
      }
      return false;
    }
    return true;
  }

  void _processUrl() async {
    final url = _urlController.text;
    if (url.isEmpty) return;

    if (!await _checkModel(_selectedModel)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stemming skipped: ${_selectedModel.name} not initialized.')),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _stemsDirectory = null;
      _videoTitle = null;
      _stemNames = null;
      _downloadProgress = 0;
      _stemmingProgress = 0;
      _downloadEta = null;
      _stemmingEta = null;
    });

    try {
      // 1. Get Metadata
      debugPrint('Fetching metadata for: $url');
      final backend = BackendFFI();
      final metadata = backend.getMetadata(url);
      debugPrint('Metadata result: $metadata');
      
      if (metadata.startsWith('Error:')) {
        if (mounted) {
          String errorMessage = metadata.replaceFirst('Error:', '').trim();
          bool isForbidden = errorMessage.contains('403') || errorMessage.toLowerCase().contains('forbidden');
          
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(isForbidden ? 'Content Unavailable' : 'Error'),
              content: Text(isForbidden 
                ? 'This video cannot be downloaded for free due to access restrictions (403 Forbidden). \n\n'
                  'This often happens with official music videos. You can try searching for a non-official version, '
                  'or wait for the upcoming "Loopback Recording" feature to record it directly from your browser.'
                : 'Failed to retrieve video information:\n\n$errorMessage'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      String title = 'stems';
      String author = '';
      if (metadata.startsWith('Title: ')) {
        final titlePart = metadata.split(', Author: ').first;
        final authorPart = metadata.split(', Author: ').last;
        title = titlePart.replaceFirst('Title: ', '');
        author = authorPart;
      }
      setState(() => _videoTitle = title);

      // Confirm with user
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Video'),
            content: Text('Do you want to process this video?\n\nTitle: $title\nAuthor: $author'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Process')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _isProcessing = false);
          return;
        }
      }

      // 2. Download Audio
      final tempDir = await getTemporaryDirectory();
      final downloadPath = p.join(tempDir.path, 'original_audio.mp4');

      final receivePort = ReceivePort();
      final downloadTracker = ProgressTracker();
      
      final isolate = await Isolate.spawn(_downloadAudioIsolate, {
        'url': url,
        'path': downloadPath,
        'sendPort': receivePort.sendPort,
      });

      await for (final message in receivePort) {
        if (message is double) {
          setState(() {
            _downloadProgress = message;
            _downloadEta = downloadTracker.calculateEta(message);
          });
        } else if (message is String?) {
          receivePort.close();
          isolate.kill();
          if (message != null) throw Exception('Download failed: $message');
          break;
        }
      }

      // 3. Split Audio (Stemming)
      final appSupportDir = await getApplicationSupportDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final outputDir = p.join(appSupportDir.path, 'stems', sanitizedTitle);
      Directory(outputDir).createSync(recursive: true);

      final downloader = ModelDownloader();
      final modelPath = await downloader.getModelPath(_selectedModel);
      final stemmingTracker = ProgressTracker();
      final stemmingReceivePort = ReceivePort();

      final stemmingIsolate = await Isolate.spawn(_splitAudioIsolate, {
        'input': downloadPath,
        'output': outputDir,
        'modelPath': modelPath,
        'stemNames': _selectedModel.stemNames,
        'sendPort': stemmingReceivePort.sendPort,
      });

      await for (final message in stemmingReceivePort) {
        if (message is double) {
          setState(() {
            _stemmingProgress = message;
            _stemmingEta = stemmingTracker.calculateEta(message);
          });
        } else if (message is String?) {
          stemmingReceivePort.close();
          stemmingIsolate.kill();
          if (message != null) {
            if (message.contains('not initialized')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stemming skipped: AI model not initialized.')),
                );
              }
              setState(() {
                _stemsDirectory = outputDir;
                _stemNames = _selectedModel.stemNames;
                _stemFiles = { for (var s in _selectedModel.stemNames) s : "$s.wav" };
              });
            } else {
              throw Exception('Stemming failed: $message');
            }
          } else {
            final stemFiles = { for (var s in _selectedModel.stemNames) s : "$s.wav" };
            setState(() {
              _stemsDirectory = outputDir;
              _stemNames = _selectedModel.stemNames;
              _stemFiles = stemFiles;
              _stemmingProgress = 1.0;
            });
            
            // Save to History
            await HistoryService().insertItem(HistoryItem(
              title: title,
              url: url,
              directory: outputDir,
              stemNames: _selectedModel.stemNames,
              stemFiles: stemFiles,
              createdAt: DateTime.now(),
            ));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing complete and saved to history!')),
              );
            }
          }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        bool isForbidden = errorStr.contains('403') || errorStr.toLowerCase().contains('forbidden');
        
        if (isForbidden) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Content Unavailable'),
              content: const Text(
                'This video cannot be downloaded for free due to access restrictions (403 Forbidden). \n\n'
                'This often happens with official music videos. You can try searching for a non-official version, '
                'or wait for the upcoming "Loopback Recording" feature to record it directly from your browser.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing failed: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _loadLocalStems() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      final List<FileSystemEntity> files = await dir.list().toList();
      
      final Map<String, String> foundStems = {};
      final commonNames = ['vocals', 'drums', 'bass', 'other', 'piano', 'guitar'];
      
      for (var file in files) {
        if (file is File) {
          final fileName = p.basename(file.path);
          final fileNameLower = fileName.toLowerCase();
          for (var stem in commonNames) {
            if (fileNameLower.contains(stem)) {
              foundStems[stem] = fileName;
              break;
            }
          }
        }
      }

      if (foundStems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No stems found in selected directory.')),
          );
        }
        return;
      }

      setState(() {
        _stemsDirectory = selectedDirectory;
        _videoTitle = p.basename(selectedDirectory);
        _stemNames = foundStems.keys.toList();
        _stemFiles = foundStems;
      });

      // Save to History (local import)
      await HistoryService().insertItem(HistoryItem(
        title: _videoTitle!,
        url: 'local:${selectedDirectory}',
        directory: selectedDirectory,
        stemNames: _stemNames!,
        stemFiles: foundStems,
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${foundStems.length} stems from: $_videoTitle')),
        );
      }
    }
  }

  void _loadFromHistory(HistoryItem item) {
    setState(() {
      _stemsDirectory = item.directory;
      _videoTitle = item.title;
      _stemNames = item.stemNames;
      _stemFiles = item.stemFiles;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded from history: ${item.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(onSelect: _loadFromHistory),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL',
                  hintText: 'Enter YouTube video URL',
                ),
                enabled: !_isProcessing,
              ),
              const SizedBox(height: 20),
              /*
              DropdownButtonFormField<AppModel>(
                value: _selectedModel,
                decoration: const InputDecoration(labelText: 'AI Model'),
                items: availableModels.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.name),
                  );
                }).toList(),
                onChanged: _isProcessing ? null : (m) {
                  if (m != null) {
                    setState(() => _selectedModel = m);
                    _checkModel(m);
                  }
                },
              ),
              */
              const SizedBox(height: 20),
              if (_isProcessing) ...[
                Column(
                  children: [
                    const Text('Downloading Video...'),
                    LinearProgressIndicator(value: _downloadProgress),
                    Text('${(_downloadProgress * 100).toStringAsFixed(1)}%${_downloadEta != null ? " (ETA: $_downloadEta)" : ""}'),
                    const SizedBox(height: 20),
                    const Text('Stemming Audio...'),
                    LinearProgressIndicator(value: _stemmingProgress),
                    Text('${(_stemmingProgress * 100).toStringAsFixed(1)}%${_stemmingEta != null ? " (ETA: $_stemmingEta)" : ""}'),
                    const SizedBox(height: 20),
                  ],
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _processUrl,
                      child: const Text('Process YouTube'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _loadLocalStems,
                      child: const Text('Load Local Stems'),
                    ),
                  ],
                ),
              if (_stemsDirectory != null) ...[
                const SizedBox(height: 40),
                const Divider(),
                const Text('Player', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                StemPlayer(
                  stemsDirectory: _stemsDirectory!,
                  videoTitle: _videoTitle ?? 'stems',
                  stemNames: _stemNames ?? ['drums', 'bass', 'other', 'vocals'],
                  stemFiles: _stemFiles ?? { for (var s in ['drums', 'bass', 'other', 'vocals']) s : "$s.wav" },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

// Compute/Isolate functions
String _getMetadataCompute(String url) {
  final backend = BackendFFI();
  return backend.getMetadata(url);
}

void _downloadAudioIsolate(Map<String, dynamic> params) {
  final backend = BackendFFI();
  final sendPort = params['sendPort'] as SendPort;
  final error = backend.downloadAudio(
    params['url'], 
    params['path'],
    onProgress: (p) => sendPort.send(p),
  );
  sendPort.send(error);
}

void _splitAudioIsolate(Map<String, dynamic> params) {
  final backend = BackendFFI();
  final sendPort = params['sendPort'] as SendPort;
  
  final modelPath = params['modelPath'];
  final libPath = BackendFFI.getOnnxRuntimePath();
  final stemNames = List<String>.from(params['stemNames']);
  
  final initError = backend.initStemmer(modelPath, libPath);
  if (initError != null) {
    sendPort.send(initError);
    return;
  }
  
  final error = backend.splitAudio(
    params['input'], 
    params['output'],
    stemNames,
    onProgress: (p) => sendPort.send(p),
  );
  sendPort.send(error);
}
