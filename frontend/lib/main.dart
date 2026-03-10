import 'package:flutter/material.dart';
import 'backend_ffi.dart';
import 'stem_player.dart';
import 'model_downloader.dart';
import 'model_download_dialog.dart';
import 'history_service.dart';
import 'history_screen.dart';
import 'log_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default to Dark for the studio look

  static const Color primaryColor = Color(0xFF7F0DF2);
  static const Color backgroundDark = Color(0xFF191022);
  static const Color surfaceDark = Color(0xFF251B30);
  static const Color borderDark = Color(0xFF3D2E4D);

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Stemmer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: backgroundDark,
        ).copyWith(
          surface: backgroundDark,
          onSurface: Colors.white,
          surfaceContainerHighest: surfaceDark,
          outline: borderDark,
        ),
        scaffoldBackgroundColor: backgroundDark,
        useMaterial3: true,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          color: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderDark),
          ),
          elevation: 0,
        ),
      ),
      themeMode: _themeMode,
      home: MyHomePage(
        title: 'YouTube Stemmer',
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onToggleTheme,
    required this.themeMode,
  });

  final String title;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
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
    
    LogService().add('Starting extraction process for: $url');

    if (!await _checkModel(_selectedModel)) {
      if (mounted) {
        setState(() => _errorMessage = 'Stemming skipped: ${_selectedModel.name} not initialized.');
        LogService().add('Error: Model not initialized');
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
      _errorMessage = null;
    });

    try {
      // 1. Get Metadata
      debugPrint('DEBUG: Calling GetMetadata for $url');
      final backend = BackendFFI();
      
      // Basic check first
      debugPrint('DEBUG: Calling CheckStatus...');
      final status = backend.checkStatus();
      debugPrint('DEBUG: CheckStatus result: $status');

      final metadata = backend.getMetadata(url);
      debugPrint('DEBUG: GetMetadata result: $metadata');
      
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
      
      // Ensure temp directory exists
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

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
          setState(() => _errorMessage = 'Processing failed: $e');
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
        title: const Text('YouTube Stemmer', style: TextStyle(fontWeight: FontWeight.bold)),
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
            tooltip: 'History',
          ),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const LogOverlay(),
              );
            },
            icon: const Icon(Icons.terminal, size: 18),
            label: const Text('Logs'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Error Display (Modernized)
              if (_errorMessage != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _errorMessage = null),
                            ),
                          ],
                        ),
                        SelectableText(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _errorMessage!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error copied to clipboard')));
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Message'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Process Video Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Process Video', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Extract stems using AI', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Paste YouTube URL here...',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: const Icon(Icons.link, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        enabled: !_isProcessing,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing ? null : _processUrl,
                              icon: const Icon(Icons.rocket_launch, size: 18),
                              label: const Text('Process'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _loadLocalStems,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Icon(Icons.folder_open_outlined),
                            ),
                          ),
                        ],
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_downloadProgress < 1.0 ? 'Downloading Audio...' : 'Stemming Audio...', 
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            if (_downloadProgress < 1.0) ...[
                              LinearProgressIndicator(value: _downloadProgress, borderRadius: BorderRadius.circular(8)),
                              const SizedBox(height: 4),
                              Text('${(_downloadProgress * 100).toStringAsFixed(1)}%${_downloadEta != null ? " (ETA: $_downloadEta)" : ""}', style: Theme.of(context).textTheme.bodySmall),
                            ] else ...[
                              LinearProgressIndicator(value: _stemmingProgress, borderRadius: BorderRadius.circular(8)),
                              const SizedBox(height: 4),
                              Text('${(_stemmingProgress * 100).toStringAsFixed(1)}%${_stemmingEta != null ? " (ETA: $_stemmingEta)" : ""}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_stemsDirectory != null) ...[
                const SizedBox(height: 24),
                Text('Active Project', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StemPlayer(
                      stemsDirectory: _stemsDirectory!,
                      videoTitle: _videoTitle ?? 'stems',
                      stemNames: _stemNames ?? ['drums', 'bass', 'other', 'vocals'],
                      stemFiles: _stemFiles ?? { for (var s in ['drums', 'bass', 'other', 'vocals']) s : "$s.wav" },
                    ),
                  ),
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
  
  // ignore: avoid_print
  print('GoIsolate: Starting initStemmer with model=$modelPath, lib=$libPath');
  
  final initError = backend.initStemmer(modelPath, libPath);
  if (initError != null) {
    // ignore: avoid_print
    print('GoIsolate: initStemmer failed: $initError');
    sendPort.send(initError);
    return;
  }
  
  // ignore: avoid_print
  print('GoIsolate: initStemmer success, starting splitAudio');
  
  final error = backend.splitAudio(
    params['input'], 
    params['output'],
    stemNames,
    onProgress: (p) => sendPort.send(p),
  );
  sendPort.send(error);
}

class LogOverlay extends StatelessWidget {
  const LogOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1015),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('system.log', style: TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: LogService().allLogs));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copied')));
                      },
                      icon: const Icon(Icons.content_copy, size: 14),
                      label: const Text('Copy'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: LogService().logs,
                builder: (context, logs, _) {
                  return ListView.builder(
                    itemCount: logs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == logs.length) return const Text('_', style: TextStyle(color: Colors.greenAccent));
                      return Text(
                        logs[index],
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
extension on ValueNotifier<List<String>> {
  get value_listenable => this;
}
