import 'package:flutter/foundation.dart';
import 'backend_ffi.dart';

String? _mixStemsCompute(Map<String, dynamic> params) {
  final backend = BackendFFI();
  final paths = List<String>.from(params['paths']);
  final weights = List<double>.from(params['weights']);
  final outputPath = params['outputPath'] as String;
  return backend.mixStems(paths, weights, outputPath);
}

String? _createZipCompute(Map<String, dynamic> params) {
  final backend = BackendFFI();
  final paths = List<String>.from(params['paths']);
  final outputPath = params['outputPath'] as String;
  return backend.createZip(paths, outputPath);
}

String? _createMp3ZipCompute(Map<String, dynamic> params) {
  final backend = BackendFFI();
  final paths = List<String>.from(params['paths']);
  final outputPath = params['outputPath'] as String;
  return backend.createMp3Zip(paths, outputPath);
}

Future<String?> mixStemsBackground({
  required List<String> paths,
  required List<double> weights,
  required String outputPath,
}) {
  return compute(_mixStemsCompute, {
    'paths': paths,
    'weights': weights,
    'outputPath': outputPath,
  });
}

Future<String?> createZipBackground({
  required List<String> paths,
  required String outputPath,
}) {
  return compute(_createZipCompute, {
    'paths': paths,
    'outputPath': outputPath,
  });
}

Future<String?> createMp3ZipBackground({
  required List<String> paths,
  required String outputPath,
}) {
  return compute(_createMp3ZipCompute, {
    'paths': paths,
    'outputPath': outputPath,
  });
}
