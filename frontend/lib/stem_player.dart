import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';
import 'export_ui.dart';
import 'export_service.dart';
import 'metronome_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StemPlayer extends StatefulWidget {
  final String stemsDirectory;
  final String videoTitle;
  final List<String> stemNames;
  final Map<String, String> stemFiles;
  final double? initialBpm;

  const StemPlayer({
    super.key,
    required this.stemsDirectory,
    required this.videoTitle,
    required this.stemNames,
    required this.stemFiles,
    this.initialBpm,
  });

  @override
  State<StemPlayer> createState() => _StemPlayerState();
}

class _StemPlayerState extends State<StemPlayer> {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, double> _userVolumes = {};
  final Set<String> _soloedStems = {};
  bool _isPlaying = false;
  bool _isExporting = false;
  String? _exportStatus;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late double _bpm;
  bool _metronomeEnabled = false;
  bool _countInEnabled = false;
  final _metronomeService = MetronomeService();
  final _clickPlayer = AudioPlayer(); // Dedicated player for click
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _bpm = widget.initialBpm ?? 120.0;
    _initPlayers();
    _initMetronome();
  }

  Future<void> _initMetronome() async {
    await _metronomeService.init();
    _metronomeService.bpm = _bpm;
  }

  @override
  void didUpdateWidget(StemPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stemsDirectory != widget.stemsDirectory) {
      _isPlaying = false;
      _initPlayers();
    }
    if (oldWidget.initialBpm != widget.initialBpm) {
      _bpm = widget.initialBpm ?? 120.0;
      _metronomeService.bpm = _bpm;
      if (mounted) setState(() {});
    }
  }

  Future<void> _initPlayers() async {
    // Dispose old players
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _userVolumes.clear();
    _soloedStems.clear();

    for (final stem in widget.stemNames) {
      final fileName = widget.stemFiles[stem] ?? '$stem.wav';
      final player = AudioPlayer();
      final file = File('${widget.stemsDirectory}/$fileName');
      if (await file.exists()) {
        await player.setFilePath(file.path);
        _players[stem] = player;
        _userVolumes[stem] = 1.0;
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

  // Each AudioPlayer runs its own MPV instance with an independent clock.
  // _startSync polls every 500 ms and seeks any player that has drifted
  // more than 50 ms from the master (first player) back into alignment.
  void _startSync() {
    _syncTimer?.cancel();
    if (_players.length <= 1) return;
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isPlaying || _players.isEmpty) return;
      final master = _players.values.first;
      final masterPos = master.position;
      for (final player in _players.values.skip(1)) {
        final drift = (player.position.inMilliseconds - masterPos.inMilliseconds).abs();
        if (drift > 50) {
          player.seek(masterPos);
        }
      }
    });
  }

  void _stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _togglePlay() async {
    if (_players.isEmpty) return;
    if (_isPlaying) {
      _stopSync();
      await Future.wait(_players.values.map((p) => p.pause()));
      _metronomeService.stop();
    } else {
      if (_countInEnabled) {
        await _metronomeService.playCountIn();
      }

      // Seek all players concurrently, then fire play on all without awaiting
      // so they start as close together as possible.
      final targetPos = _players.values.first.position;
      await Future.wait(_players.values.map((p) => p.seek(targetPos)));
      for (final player in _players.values) {
        player.play();
      }
      _startSync();

      if (_metronomeEnabled) {
        _metronomeService.start();
      }
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  void _stop() async {
    if (_players.isEmpty) return;
    _stopSync();
    await Future.wait(_players.values.map((p) => p.pause()));
    await Future.wait(_players.values.map((p) => p.seek(Duration.zero)));
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
  }

  void _skipBack() async {
    if (_players.isEmpty) return;
    final newPos = _position - const Duration(seconds: 10);
    final targetPos = newPos < Duration.zero ? Duration.zero : newPos;
    await Future.wait(_players.values.map((p) => p.seek(targetPos)));
    setState(() => _position = targetPos);
  }

  void _skipForward() async {
    if (_players.isEmpty) return;
    final newPos = _position + const Duration(seconds: 10);
    final targetPos = newPos > _duration ? _duration : newPos;
    await Future.wait(_players.values.map((p) => p.seek(targetPos)));
    setState(() => _position = targetPos);
  }

  void _seek(Duration position) async {
    if (_players.isEmpty) return;
    await Future.wait(_players.values.map((p) => p.seek(position)));
    setState(() => _position = position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _setVolume(String stem, double volume) {
    _userVolumes[stem] = volume;
    _updateEffectiveVolumes();
    setState(() {});
  }

  void _toggleSolo(String stem) {
    setState(() {
      if (_soloedStems.contains(stem)) {
        _soloedStems.remove(stem);
      } else {
        _soloedStems.add(stem);
      }
      _updateEffectiveVolumes();
    });
  }

  void _updateEffectiveVolumes() {
    final hasSolo = _soloedStems.isNotEmpty;
    for (final stem in widget.stemNames) {
      final player = _players[stem];
      if (player == null) continue;

      if (hasSolo) {
        if (_soloedStems.contains(stem)) {
          player.setVolume(_userVolumes[stem] ?? 1.0);
        } else {
          player.setVolume(0.0);
        }
      } else {
        player.setVolume(_userVolumes[stem] ?? 1.0);
      }
    }
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

  void _showBpmEditor() {
    final controller = TextEditingController(text: _bpm.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tempo (BPM)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'BPM'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newBpm = double.tryParse(controller.text);
              if (newBpm != null && newBpm > 0) {
                setState(() {
                  _bpm = newBpm;
                  _metronomeService.bpm = newBpm;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isSelected ? 0.5 : 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_players.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            widget.videoTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Player Controls Section
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Timeline
                Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text(
                        _formatDuration(_position),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                          min: 0,
                          max: _duration.inMilliseconds.toDouble() == 0 ? 1 : _duration.inMilliseconds.toDouble(),
                          onChanged: (v) => _seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 45,
                      child: Text(
                        _formatDuration(_duration),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Playback Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.replay_10),
                      onPressed: _skipBack,
                      tooltip: 'Back 10s',
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.stop_rounded),
                      onPressed: _stop,
                      tooltip: 'Stop',
                    ),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      iconSize: 40,
                      onPressed: _togglePlay,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.forward_10),
                      onPressed: _skipForward,
                      tooltip: 'Forward 10s',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // BPM Display & Override
            InkWell(
              onTap: _showBpmEditor,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_bpm.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.amber, fontFamily: 'monospace', height: 1.0),
                    ),
                    const Text(
                      'BPM',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Metronome & Count-in Switches
            _buildControlToggle(
              icon: Icons.av_timer,
              label: 'METRONOME',
              isSelected: _metronomeEnabled,
              onTap: () {
                setState(() => _metronomeEnabled = !_metronomeEnabled);
                if (!_metronomeEnabled) _metronomeService.stop();
              },
            ),
            const SizedBox(width: 12),
            _buildControlToggle(
              icon: Icons.more_time_rounded,
              label: 'COUNT-IN',
              isSelected: _countInEnabled,
              onTap: () => setState(() => _countInEnabled = !_countInEnabled),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'STUDIO MIXER',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Studio Mixer (Grid of vertical lanes)
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.stemNames.map((stem) {
                final hasFile = _players.containsKey(stem);
                final volume = _players[stem]?.volume ?? 1.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stem.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 10,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: _soloedStems.isNotEmpty && !_soloedStems.contains(stem)
                                      ? Colors.grey.withOpacity(0.3)
                                      : Theme.of(context).colorScheme.primary,
                                  inactiveTrackColor: Theme.of(context).colorScheme.surface,
                                ),
                                child: Slider(
                                  value: _userVolumes[stem] ?? 1.0,
                                  onChanged: hasFile ? (v) => _setVolume(stem, v) : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Text('M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: hasFile ? () => _setVolume(stem, (_userVolumes[stem] ?? 1.0) == 0 ? 1.0 : 0.0) : null,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(28, 28),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: (_userVolumes[stem] ?? 1.0) == 0 ? Colors.red.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
                                  foregroundColor: (_userVolumes[stem] ?? 1.0) == 0 ? Colors.red : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: hasFile ? () => _toggleSolo(stem) : null,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(28, 28),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: _soloedStems.contains(stem) ? Colors.amber.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
                                  foregroundColor: _soloedStems.contains(stem) ? Colors.amber : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        ),

        const Divider(height: 48),
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
    _stopSync();
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}
