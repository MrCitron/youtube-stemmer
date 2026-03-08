import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppModel {
  final String id;
  final String name;
  final String url;
  final String fileName;
  final List<String> stemNames;
  final String description;

  const AppModel({
    required this.id,
    required this.name,
    required this.url,
    required this.fileName,
    required this.stemNames,
    required this.description,
  });
}

const List<AppModel> availableModels = [
  AppModel(
    id: 'htdemucs',
    name: 'HTDemucs (4-track)',
    url: 'https://huggingface.co/MrCitron/demucs-v4-onnx/resolve/main/htdemucs.onnx?download=true',
    fileName: 'htdemucs.onnx',
    stemNames: ['drums', 'bass', 'other', 'vocals'],
    description: 'Standard 4-track separation (Drums, Bass, Vocals, Other).',
  ),
  AppModel(
    id: 'htdemucs_ft',
    name: 'HTDemucs Fine-tuned (4-track)',
    url: 'https://huggingface.co/MrCitron/demucs-v4-onnx/resolve/main/htdemucs_ft.onnx?download=true',
    fileName: 'htdemucs_ft.onnx',
    stemNames: ['drums', 'bass', 'other', 'vocals'],
    description: 'Higher quality 4-track separation (Best for vocals/drums).',
  ),
];

class ModelDownloader {
  final Dio _dio;
  final String? _basePath;

  ModelDownloader({Dio? dio, String? basePath}) 
      : _dio = dio ?? Dio(),
        _basePath = basePath;

  Future<String> getModelPath(AppModel model) async {
    final String base;
    if (_basePath != null) {
      base = _basePath!;
    } else {
      final directory = await getApplicationSupportDirectory();
      base = directory.path;
    }
    final modelsDir = Directory(p.join(base, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return p.join(modelsDir.path, model.fileName);
  }

  Future<bool> isModelDownloaded(AppModel model) async {
    final path = await getModelPath(model);
    return File(path).exists();
  }

  Future<void> downloadModel({
    required AppModel model,
    required Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final path = await getModelPath(model);
    final tempPath = '$path.download';

    try {
      await _dio.download(
        model.url,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Rename temp file to actual file on success
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(path);
      }
    } catch (e) {
      // Cleanup temp file on failure or cancellation
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
