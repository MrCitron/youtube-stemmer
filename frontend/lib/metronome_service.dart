import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';

class MetronomeService {
  AudioPlayer? _player;
  Timer? _timer;
  double _bpm = 120.0;
  bool _isPlaying = false;

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
    if (_player != null) return;
    _player = AudioPlayer();
    
    try {
      await _player?.setAsset('assets/click.wav', preload: true);
      await _player?.setVolume(1.0);
      await _player?.load();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading metronome click asset: $e');
    }
  }

  void start({Stream<Duration>? positionStream}) {
    if (_isPlaying) return;
    _isPlaying = true;
    
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _timer = Timer.periodic(interval, (timer) {
      _playClick();
    });
    _playClick(); 
  }

  void stop() {
    _timer?.cancel();
    _isPlaying = false;
  }

  Future<void> playCountIn() async {
    await init();
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    for (int i = 0; i < 4; i++) {
      _playClick();
      await Future.delayed(interval);
    }
  }

  void _playClick() {
    if (_player == null) return;
    
    // ignore: avoid_print
    print('Metronome: Click at BPM $_bpm');

    // On Linux, we might need a more reliable way if multiple players conflict.
    // But for now we try to ensure it plays.
    _player?.seek(Duration.zero);
    _player?.play();

    // FALLBACK for Linux: If system has 'paplay' (PulseAudio) or 'aplay' (ALSA)
    // we can trigger it directly to verify if it's a just_audio limitation.
    // This is ONLY for debugging purposes if still silent.
  }

  void dispose() {
    stop();
    _player?.dispose();
  }
}
