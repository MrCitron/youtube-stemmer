import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'export_ui.dart';
import 'export_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StemPlayer extends StatefulWidget {
  final String stemsDirectory;
  final String videoTitle;
  final List<String> stemNames;
  final Map<String, String> stemFiles;

  const StemPlayer({
    super.key,
    required this.stemsDirectory,
    required this.videoTitle,
    required this.stemNames,
    required this.stemFiles,
  });

  @override
  State<StemPlayer> createState() => _StemPlayerState();
}

class _StemPlayerState extends State<StemPlayer> {
  final Map<String, AudioPlayer> _players = {};
  bool _isPlaying = false;
  bool _isExporting = false;
  String? _exportStatus;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayers();
  }

  @override
  void didUpdateWidget(StemPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stemsDirectory != widget.stemsDirectory) {
      _isPlaying = false;
      _initPlayers();
    }
  }

  Future<void> _initPlayers() async {
    // Dispose old players
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();

    for (final stem in widget.stemNames) {
      final fileName = widget.stemFiles[stem] ?? '$stem.wav';
      final player = AudioPlayer();
      final file = File('${widget.stemsDirectory}/$fileName');
      if (await file.exists()) {
        await player.setFilePath(file.path);
        _players[stem] = player;
      }
    }

    if (_players.isNotEmpty) {
      // Synchronize players
      final firstPlayer = _players.values.first;
      firstPlayer.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      firstPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    }
  }

  void _togglePlay() async {
    if (_players.isEmpty) return;
    if (_isPlaying) {
      for (final player in _players.values) {
        await player.pause();
      }
    } else {
      // Ensure all players are at the same position before playing
      final targetPos = _players.values.first.position;
      for (final player in _players.values) {
        await player.seek(targetPos);
        player.play();
      }
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _stop() async {
    if (_players.isEmpty) return;
    for (final player in _players.values) {
      await player.pause();
      await player.seek(Duration.zero);
    }
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
  }

  void _skipBack() async {
    if (_players.isEmpty) return;
    final newPos = _position - const Duration(seconds: 10);
    final targetPos = newPos < Duration.zero ? Duration.zero : newPos;
    for (final player in _players.values) {
      await player.seek(targetPos);
    }
    setState(() => _position = targetPos);
  }

  void _skipForward() async {
    if (_players.isEmpty) return;
    final newPos = _position + const Duration(seconds: 10);
    final targetPos = newPos > _duration ? _duration : newPos;
    for (final player in _players.values) {
      await player.seek(targetPos);
    }
    setState(() => _position = targetPos);
  }

  void _seek(Duration position) async {
    if (_players.isEmpty) return;
    for (final player in _players.values) {
      await player.seek(position);
    }
    setState(() => _position = position);
  }

  void _setVolume(String stem, double volume) {
    _players[stem]?.setVolume(volume);
    setState(() {});
  }

  Future<void> _handleExportZip(ExportFormat format) async {
    final downloadsDir = await getDownloadsDirectory();
    final defaultPath = downloadsDir?.path;
    
    // Sanitize filename
    final sanitizedTitle = widget.videoTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = '${sanitizedTitle}_stems.zip';

    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: fileName,
      initialDirectory: defaultPath,
      acceptedTypeGroups: [
        const XTypeGroup(label: 'ZIP', extensions: ['zip']),
      ],
    );

    if (result == null) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Packaging ZIP archive...';
    });
    try {
      final paths = widget.stemNames.map((s) {
        final fileName = widget.stemFiles[s] ?? '$s.wav';
        return '${widget.stemsDirectory}/$fileName';
      }).toList();
      
      // Validate all stems exist
      for (final path in paths) {
        if (!await File(path).exists()) {
          throw Exception('Stem file not found: ${p.basename(path)}');
        }
      }

      final String? error;
      if (format == ExportFormat.mp3) {
        setState(() => _exportStatus = 'Encoding stems to MP3 and Zipping...');
        error = await createMp3ZipBackground(paths: paths, outputPath: result.path);
      } else {
        error = await createZipBackground(paths: paths, outputPath: result.path);
      }
      
      if (error != null) throw Exception(error);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${result.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportMix(ExportFormat format) async {
    final downloadsDir = await getDownloadsDirectory();
    final defaultPath = downloadsDir?.path;
    final sanitizedTitle = widget.videoTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final extension = format.name;
    final fileName = '$sanitizedTitle.$extension';

    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: fileName,
      initialDirectory: defaultPath,
      acceptedTypeGroups: [
        XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
      ],
    );

    if (result == null) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Mixing and encoding stems...';
    });
    try {
      final activeStems = _players.keys.toList();
      final paths = activeStems.map((s) {
        final fileName = widget.stemFiles[s] ?? '$s.wav';
        return '${widget.stemsDirectory}/$fileName';
      }).toList();
      final weights = activeStems.map((s) => _players[s]?.volume ?? 0.0).toList();
      
      // Validate all stems exist
      for (final path in paths) {
        if (!await File(path).exists()) {
          throw Exception('Stem file not found: ${p.basename(path)}');
        }
      }

      final error = await mixStemsBackground(
        paths: paths,
        weights: weights,
        outputPath: result.path,
      );
      if (error != null) throw Exception(error);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${result.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            widget.videoTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(_position.toString().split('.').first),
              Expanded(
                child: Slider(
                  value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                  min: 0,
                  max: _duration.inMilliseconds.toDouble() == 0 ? 1 : _duration.inMilliseconds.toDouble(),
                  onChanged: (v) => _seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              Text(_duration.toString().split('.').first),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              onPressed: _skipBack,
              tooltip: 'Back 10s',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stop,
              tooltip: 'Stop',
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlay,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.fast_forward),
              onPressed: _skipForward,
              tooltip: 'Forward 10s',
            ),
          ],
        ),
        ...widget.stemNames.map((stem) {
          final hasFile = _players.containsKey(stem);
          return ListTile(
            title: Text(stem.toUpperCase()),
            subtitle: hasFile
                ? Slider(
                    value: _players[stem]?.volume ?? 1.0,
                    onChanged: (v) => _setVolume(stem, v),
                  )
                : const Text('File not found'),
            trailing: hasFile
                ? IconButton(
                    icon: Icon(_players[stem]?.volume == 0 ? Icons.volume_off : Icons.volume_up),
                    onPressed: () => _setVolume(stem, _players[stem]?.volume == 0 ? 1.0 : 0.0),
                  )
                : null,
          );
        }),
        const Divider(),
        ExportUI(
          stemVolumes: _players.map((k, v) => MapEntry(k, v.volume)),
          onExportZip: _handleExportZip,
          onExportMix: _handleExportMix,
          isProcessing: _isExporting,
          statusMessage: _exportStatus,
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}
