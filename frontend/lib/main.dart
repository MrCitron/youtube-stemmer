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
import 'package:file_selector/file_selector.dart' show getDirectoryPath;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'package:just_audio_media_kit/just_audio_media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Ensure the application support directory exists early, 
      // as some plugins might fail if it's missing on first run.
      final appSupportDir = await getApplicationSupportDirectory();
      if (!await appSupportDir.exists()) {
        await appSupportDir.create(recursive: true);
      }

      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(600, 1100),
        center: true,
        title: 'YouTube Stemmer',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setMinimumSize(const Size(600, 800));
      });

      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    JustAudioMediaKit.ensureInitialized();
    runApp(const MyApp());
  } catch (e, stack) {
    // If it fails before runApp, the screen remains white.
    // We try to log to a file for diagnosis in both the working dir and support dir.
    try {
      final logContent = 'Error: $e\nStack: $stack';
      await File('startup_error.log').writeAsString(logContent);
      
      final appSupportDir = await getApplicationSupportDirectory();
      await File(p.join(appSupportDir.path, 'startup_error.log')).writeAsString(logContent);
    } catch (_) {
      // ignore
    }
    rethrow;
  }
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
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // Use Auto by default

  static const Color primaryColor = Color(0xFF7F0DF2);
  static const Color backgroundDark = Color(0xFF191022);
  static const Color surfaceDark = Color(0xFF251B30);
  static const Color borderDark = Color(0xFF3D2E4D);

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final themeStr = await HistoryService().getSetting('themeMode');
    if (themeStr != null) {
      setState(() {
        if (themeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else if (themeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      });
    }
  }

  ThemeMode getThemeMode() => _themeMode;

  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        _themeMode = ThemeMode.light;
      } else if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      _saveThemePreference();
    });
  }

  Future<void> _saveThemePreference() async {
    String themeStr = 'system';
    if (_themeMode == ThemeMode.light) {
      themeStr = 'light';
    } else if (_themeMode == ThemeMode.dark) {
      themeStr = 'dark';
    }
    await HistoryService().saveSetting('themeMode', themeStr);
  }

  @override
  Widget build(BuildContext context) {
    const Color lightPrimary = Color(0xFFBB86FC);
    final lightColorScheme = ColorScheme.fromSeed(seedColor: lightPrimary).copyWith(
      primary: lightPrimary,
      onPrimary: Colors.white,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: backgroundDark,
    ).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      surface: backgroundDark,
      onSurface: Colors.white,
      surfaceContainerHighest: surfaceDark,
      outline: borderDark,
    );

    return MaterialApp(
      title: 'YouTube Stemmer',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        fontFamily: 'Inter',
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return lightColorScheme.primary;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return lightColorScheme.onSurface;
            }),
          ),
        ),
        cardTheme: CardThemeData(
          color: lightColorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: lightColorScheme.outline.withValues(alpha: 0.1)),
          ),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: backgroundDark,
        useMaterial3: true,
        fontFamily: 'Inter',
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return darkColorScheme.primary;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return darkColorScheme.onSurface;
            }),
          ),
        ),
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
        onToggleTheme: toggleTheme,
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
  final FocusNode _urlFocusNode = FocusNode();
  bool _isProcessing = false;
  Isolate? _downloadIsolate;
  Isolate? _stemmingIsolate;
  ReceivePort? _downloadReceivePort;
  ReceivePort? _stemmingReceivePort;
  String? _currentDownloadPath;
  String? _currentOutputDir;

  bool _isCancelling = false;
  void _cancelProcessing() async {
    if (_isCancelling) return;
    _isCancelling = true;
    
    LogService().info('Cancellation requested by user.');
    
    // Signal the native backend to abort its tasks.
    BackendFFI().cancelTasks();
    
    // Free the stemmer session to release locks and resources.
    BackendFFI().freeStemmer();
    
    // Brief delay to allow the native library to recognize the abort signal 
    // and stop invoking any callbacks into Dart, avoiding crashes during unwind.
    await Future.delayed(const Duration(milliseconds: 200));

    _downloadReceivePort?.close();
    _stemmingReceivePort?.close();
    _downloadReceivePort = null;
    _stemmingReceivePort = null;

    _downloadIsolate?.kill(priority: Isolate.immediate);
    _stemmingIsolate?.kill(priority: Isolate.immediate);
    _downloadIsolate = null;
    _stemmingIsolate = null;
    _isCancelling = false;

    // Cleanup files
    if (_currentDownloadPath != null) {
      final f = File(_currentDownloadPath!);
      if (await f.exists()) {
        await f.delete();
        LogService().debug('Cleaned up partial download: $_currentDownloadPath');
      }
    }
    if (_currentOutputDir != null) {
      final d = Directory(_currentOutputDir!);
      if (await d.exists()) {
        await d.delete(recursive: true);
        LogService().debug('Cleaned up partial stems directory: $_currentOutputDir');
      }
    }

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Process cancelled by user.')),
      );
    }
  }

  String? _errorMessage;
  String? _stemsDirectory;
  String? _videoTitle;
  List<String>? _stemNames;
  Map<String, String>? _stemFiles;
  double? _bpm;
  int? _currentHistoryId;

  double _downloadProgress = 0;
  double _stemmingProgress = 0;
  String? _downloadEta;
  String? _stemmingEta;

  List<Map<String, dynamic>> _urlHistory = [];

  final AppModel _selectedModel = availableModels.first;

  @override
  void initState() {
    super.initState();
    _loadUrlHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModel(_selectedModel);
      _urlFocusNode.requestFocus();
    });
  }

  Future<void> _loadUrlHistory() async {
    final history = await HistoryService().getUrlHistory();
    if (mounted) {
      setState(() {
        _urlHistory = history;
      });
    }
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
    
    LogService().info('Starting extraction process for: $url');

    if (!await _checkModel(_selectedModel)) {
      if (mounted) {
        setState(() => _errorMessage = 'Stemming skipped: ${_selectedModel.name} not initialized.');
        LogService().error('Error: Model not initialized');
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
      // 1. Get Metadata (run off the main thread to avoid UI freeze)
      LogService().debug('Calling GetMetadata for $url');
      final metadata = await compute(_getMetadataCompute, url);
      LogService().debug('GetMetadata result: $metadata');
      
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
      LogService().info('Download started for: $title');
      final tempDir = await getTemporaryDirectory();
      final downloadPath = p.join(tempDir.path, 'original_audio.mp4');
      _currentDownloadPath = downloadPath;
      
      // Ensure temp directory exists
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      _downloadReceivePort = ReceivePort();
      final downloadTracker = ProgressTracker();
      
      final isolate = await Isolate.spawn(_downloadAudioIsolate, {
        'url': url,
        'path': downloadPath,
        'sendPort': _downloadReceivePort!.sendPort,
      });
      _downloadIsolate = isolate;

      await for (final message in _downloadReceivePort!) {
        if (message is double) {
          setState(() {
            _downloadProgress = message;
            _downloadEta = downloadTracker.calculateEta(message);
          });
        } else if (message is String?) {
          _downloadReceivePort?.close();
          _downloadReceivePort = null;
          isolate.kill();
          if (message != null) throw Exception('Download failed: $message');
          break;
        }
      }

      if (!_isProcessing) {
        LogService().info('Download step interrupted by cancellation.');
        return;
      }

      // 3. Split Audio (Stemming)
      LogService().info('Download complete. Starting stemming.');
      final appSupportDir = await getApplicationSupportDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final outputDir = p.join(appSupportDir.path, 'stems', sanitizedTitle);
      _currentOutputDir = outputDir;
      Directory(outputDir).createSync(recursive: true);

      final downloader = ModelDownloader();
      final modelPath = await downloader.getModelPath(_selectedModel);
      final stemmingTracker = ProgressTracker();
      _stemmingReceivePort = ReceivePort();

      final stemmingIsolate = await Isolate.spawn(_splitAudioIsolate, {
        'input': downloadPath,
        'output': outputDir,
        'modelPath': modelPath,
        'stemNames': _selectedModel.stemNames,
        'sendPort': _stemmingReceivePort!.sendPort,
      });
      _stemmingIsolate = stemmingIsolate;

      await for (final message in _stemmingReceivePort!) {
        if (message is double) {
          setState(() {
            _stemmingProgress = message;
            _stemmingEta = stemmingTracker.calculateEta(message);
          });
        } else if (message is String?) {
          _stemmingReceivePort?.close();
          _stemmingReceivePort = null;
          stemmingIsolate.kill();
          if (message != null) {
            if (message.contains('not initialized')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stemming skipped: AI model not initialized.')),
                );
              }

              // 4. BPM Analysis (even if stemming is skipped)
              LogService().info('Starting BPM analysis (stemming skipped)...');
              double? estimatedBpm;
              try {
                final bpmStr = BackendFFI().getEstimatedBPM(downloadPath);
                if (!bpmStr.contains('Error')) {
                  estimatedBpm = double.tryParse(bpmStr);
                  LogService().info('Estimated BPM: $estimatedBpm');
                }
              } catch (e) {
                LogService().warn('BPM analysis error: $e');
              }

              setState(() {
                _stemsDirectory = outputDir;
                _stemNames = _selectedModel.stemNames;
                _stemFiles = { for (var s in _selectedModel.stemNames) s : "$s.wav" };
                _bpm = estimatedBpm;
              });
            } else {
              throw Exception('Stemming failed: $message');
            }
          } else {
            final stemFiles = { for (var s in _selectedModel.stemNames) s : "$s.wav" };
            
            // 4. BPM Analysis
            LogService().info('Starting BPM analysis...');
            double? estimatedBpm;
            try {
              final bpmStr = BackendFFI().getEstimatedBPM(downloadPath);
              if (!bpmStr.contains('Error')) {
                estimatedBpm = double.tryParse(bpmStr);
                LogService().info('Estimated BPM: $estimatedBpm');
              } else {
                LogService().warn('BPM analysis failed: $bpmStr');
              }
            } catch (e) {
              LogService().warn('BPM analysis error: $e');
            }

            // Save to History
            final newItem = HistoryItem(
              title: title,
              url: url,
              directory: outputDir,
              stemNames: _selectedModel.stemNames,
              stemFiles: stemFiles,
              bpm: estimatedBpm,
              createdAt: DateTime.now(),
            );
            final id = await HistoryService().insertItem(newItem);

            setState(() {
              _stemsDirectory = outputDir;
              _stemNames = _selectedModel.stemNames;
              _stemFiles = stemFiles;
              _bpm = estimatedBpm;
              _stemmingProgress = 1.0;
              _currentHistoryId = id;
            });
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
      if (_isCancelling) {
        LogService().info('Process catch: ignoring error because user is cancelling.');
        return;
      }
      LogService().error('Process failed: $e');
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
    String? selectedDirectory = await getDirectoryPath();

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
        _bpm = null;
      });

      // Detect BPM (prefer drums, fallback to first stem)
      final analysisFileName = foundStems['drums'] ?? foundStems.values.first;
      final analysisPath = p.join(selectedDirectory, analysisFileName);
      final detectedBpm = await compute(_getBpmCompute, analysisPath);
      if (mounted) setState(() => _bpm = detectedBpm);

      // Save to History (local import)
      final id = await HistoryService().insertItem(HistoryItem(
        title: _videoTitle!,
        url: 'local:$selectedDirectory',
        directory: selectedDirectory,
        stemNames: _stemNames!,
        stemFiles: foundStems,
        bpm: detectedBpm,
        createdAt: DateTime.now(),
      ));

      setState(() {
        _currentHistoryId = id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${foundStems.length} stems from: $_videoTitle')),
        );
      }
    }
  }

  void _handleTitleChanged(String newTitle) async {
    if (_currentHistoryId != null) {
      await HistoryService().updateItemTitle(_currentHistoryId!, newTitle);
      setState(() {
        _videoTitle = newTitle;
      });
    } else {
      setState(() {
        _videoTitle = newTitle;
      });
    }
  }

  void _loadFromHistory(HistoryItem item) {
    setState(() {
      _stemsDirectory = item.directory;
      _videoTitle = item.title;
      _stemNames = item.stemNames;
      _stemFiles = item.stemFiles;
      _bpm = item.bpm;
      _currentHistoryId = item.id;
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
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.system
                  ? Icons.brightness_auto_rounded
                  : widget.themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme (Auto/Light/Dark)',
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text('PROCESS VIDEO', 
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RawAutocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return _urlHistory.where((Map<String, dynamic> option) {
                            return option['url'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                option['title'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Map<String, dynamic> option) => option['url'],
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          // Initial sync from outer to inner if needed
                          if (_urlController.text.isNotEmpty && textEditingController.text.isEmpty) {
                            textEditingController.text = _urlController.text;
                          }

                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Paste YouTube URL here...',
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark 
                                  ? Theme.of(context).colorScheme.surface 
                                  : Colors.white.withValues(alpha: 0.5),
                              prefixIcon: const Icon(Icons.link, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            enabled: !_isProcessing,
                            onChanged: (value) => _urlController.text = value,
                            onSubmitted: (_) => _processUrl(),
                          );
                        },
                        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surface,
                              child: Container(
                                width: 500, // Reasonable width for dropdown
                                constraints: const BoxConstraints(maxHeight: 300),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Map<String, dynamic> option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option['title'] ?? 'Unknown Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(option['url'], style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (Map<String, dynamic> selection) {
                          _urlController.text = selection['url'];
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing ? null : _processUrl,
                              icon: const Icon(Icons.rocket_launch, size: 18),
                              label: const Text('Process'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _loadLocalStems,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Icon(Icons.folder_open_outlined, size: 20),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_downloadProgress < 1.0 ? 'Downloading Audio...' : 'Stemming Audio...', 
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                                TextButton.icon(
                                  onPressed: _cancelProcessing,
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'PLAYER',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StemPlayer(
                  stemsDirectory: _stemsDirectory!,
                  videoTitle: _videoTitle ?? 'stems',
                  stemNames: _stemNames ?? ['drums', 'bass', 'other', 'vocals'],
                  stemFiles: _stemFiles ?? { for (var s in ['drums', 'bass', 'other', 'vocals']) s : "$s.wav" },
                  initialBpm: _bpm,
                  onTitleChanged: _handleTitleChanged,
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
    _urlFocusNode.dispose();
    super.dispose();
  }
}

// Compute/Isolate functions
String _getMetadataCompute(String url) {
  final backend = BackendFFI();
  return backend.getMetadata(url);
}

double? _getBpmCompute(String path) {
  final backend = BackendFFI();
  final result = backend.getEstimatedBPM(path);
  if (result.startsWith('Error:')) return null;
  return double.tryParse(result);
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

class LogOverlay extends StatefulWidget {
  const LogOverlay({super.key});

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  LogLevel _selectedLevel = LogLevel.debug;

  bool _shouldShow(LogLevel entryLevel) {
    if (_selectedLevel == LogLevel.error) return entryLevel == LogLevel.error;
    if (_selectedLevel == LogLevel.info) return entryLevel == LogLevel.info || entryLevel == LogLevel.error;
    return true; // Debug shows everything
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F1015),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SegmentedButton<LogLevel>(
                segments: const [
                  ButtonSegment(value: LogLevel.error, label: Text('ERROR', style: TextStyle(fontSize: 10))),
                  ButtonSegment(value: LogLevel.info, label: Text('INFO', style: TextStyle(fontSize: 10))),
                  ButtonSegment(value: LogLevel.debug, label: Text('DEBUG', style: TextStyle(fontSize: 10))),
                ],
                selected: {_selectedLevel},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedLevel = newSelection.first;
                  });
                },
                multiSelectionEnabled: false,
                emptySelectionAllowed: false,
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.black.withValues(alpha: 0.05);
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.white70;
                  }),
                  side: WidgetStateProperty.all(const BorderSide(color: Colors.white24)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<LogEntry>>(
                valueListenable: LogService().entries,
                builder: (context, entries, _) {
                  final filteredEntries = entries.where((e) => _shouldShow(e.level)).toList();
                  return ListView.builder(
                    itemCount: filteredEntries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredEntries.length) return const Text('_', style: TextStyle(color: Colors.greenAccent));
                      final entry = filteredEntries[index];
                      Color color = Colors.greenAccent;
                      if (entry.level == LogLevel.error) color = Colors.redAccent;
                      if (entry.level == LogLevel.debug) color = Colors.blueAccent;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          entry.toString(),
                          style: TextStyle(fontFamily: 'monospace', color: color, fontSize: 11),
                        ),
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
