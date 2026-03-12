import 'dart:async';
import 'package:just_audio/just_audio.dart';

class MetronomeService {
  AudioPlayer? _regularPlayer;
  AudioPlayer? _downbeatPlayer;
  Timer? _timer;
  double _bpm = 120.0;
  bool _isPlaying = false;
  int _beatCount = 0; // 0 = downbeat (beat 1), 1-3 = regular beats

  double get bpm => _bpm;
  bool get isPlaying => _isPlaying;

  set bpm(double value) {
    _bpm = value;
    if (_isPlaying) {
      stop();
      start();
    }
  }

  Future<void> init() async {
    if (_regularPlayer != null) return;
    _regularPlayer = AudioPlayer();
    _downbeatPlayer = AudioPlayer();
    try {
      await _regularPlayer?.setAsset('assets/click.wav', preload: true);
      await _downbeatPlayer?.setAsset('assets/click_down.wav', preload: true);
      await _regularPlayer?.setVolume(1.0);
      await _downbeatPlayer?.setVolume(1.0);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading metronome click assets: $e');
    }
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _beatCount = 0;
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _playClick();
    _timer = Timer.periodic(interval, (_) => _playClick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPlaying = false;
    _beatCount = 0;
  }

  /// Plays a 4-beat count-in. Seeks are done by the caller before invoking this.
  /// Returns after the 4th beat + one full interval so the caller can fire play()
  /// exactly on the downbeat.
  Future<void> playCountIn() async {
    await init();
    final intervalMs = (60000.0 / _bpm).round();
    for (int i = 0; i < 4; i++) {
      _playClickAtBeat(i);
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
  }

  void _playClick() {
    _playClickAtBeat(_beatCount % 4);
    _beatCount++;
  }

  void _playClickAtBeat(int beatInMeasure) {
    if (beatInMeasure == 0) {
      _downbeatPlayer?.seek(Duration.zero);
      _downbeatPlayer?.play();
    } else {
      _regularPlayer?.seek(Duration.zero);
      _regularPlayer?.play();
    }
  }

  void dispose() {
    stop();
    _regularPlayer?.dispose();
    _downbeatPlayer?.dispose();
    _regularPlayer = null;
    _downbeatPlayer = null;
  }
}
