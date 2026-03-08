import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/backend_ffi.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  late BackendFFI backend;

  setUp(() {
    backend = BackendFFI();
  });

  test('FFI HelloWorld call', () {
    try {
      backend.helloWorld();
    } catch (e) {
      fail('FFI call failed: $e');
    }
  });

  test('FFI GetMetadata call', () {
    const url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"; // Rickroll
    try {
      final metadata = backend.getMetadata(url);
      print('Metadata: $metadata');
      expect(metadata, contains('Rick Astley'));
      expect(metadata, contains('Never Gonna Give You Up'));
    } catch (e) {
      fail('FFI GetMetadata failed: $e');
    }
  });

  test('FFI DownloadAudio call', () {
    const url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    final tmpDir = Directory.systemTemp.createTempSync('yt_stem_test');
    final outputPath = p.join(tmpDir.path, 'audio.mp4');
    
    try {
      print('Downloading audio to: $outputPath');
      final error = backend.downloadAudio(url, outputPath);
      if (error != null) {
        fail('FFI DownloadAudio failed: $error');
      }
      
      final file = File(outputPath);
      expect(file.existsSync(), true, reason: 'Output file must exist');
      expect(file.lengthSync(), greaterThan(1000), reason: 'Output file must not be empty');
      
      // Cleanup
      tmpDir.deleteSync(recursive: true);
    } catch (e) {
      fail('FFI DownloadAudio failed: $e');
    }
  });

  test('FFI InitStemmer and SplitAudio calls', () {
    const modelPath = "models/htdemucs.onnx";
    final libPath = BackendFFI.getOnnxRuntimePath();
    
    // We expect failure if the files are not present
    final error = backend.initStemmer(modelPath, libPath);
    if (error != null) {
      print('InitStemmer failed as expected: $error');
    } else {
      print('InitStemmer succeeded (unexpected without model file)');
    }

    final splitError = backend.splitAudio("input.mp4", "output/");
    if (splitError != null) {
      print('SplitAudio failed as expected: $splitError');
    } else {
      print('SplitAudio succeeded (dummy call)');
    }
  });

  test('FFI Full Stemming Integration', () {
    final projectRoot = p.dirname(Directory.current.path);
    final modelPath = p.join(projectRoot, 'backend', 'models', 'htdemucs.onnx');
    final libPath = BackendFFI.getOnnxRuntimePath();
    final inputPath = p.join(projectRoot, 'backend', 'test_input.wav');
    final outputDir = Directory.systemTemp.createTempSync('yt_stem_full').path;

    try {
      print('Initializing Stemmer...');
      final initError = backend.initStemmer(modelPath, libPath);
      if (initError != null) {
        fail('FFI InitStemmer failed: $initError');
      }

      print('Starting Full Stemming for: $inputPath');
      final splitError = backend.splitAudio(inputPath, outputDir);
      if (splitError != null) {
        fail('FFI SplitAudio failed: $splitError');
      }

      print('Stemming complete. Checking output files in $outputDir');
      final stems = ['vocals.wav', 'drums.wav', 'bass.wav', 'other.wav'];
      for (final stem in stems) {
        final file = File(p.join(outputDir, stem));
        expect(file.existsSync(), true, reason: 'Output file $stem must exist');
        expect(file.lengthSync(), greaterThan(1000), reason: 'Output file $stem must not be empty');
      }

      // Cleanup
      Directory(outputDir).deleteSync(recursive: true);
    } catch (e) {
      fail('FFI Full Stemming Integration failed: $e');
    }
  });
}
