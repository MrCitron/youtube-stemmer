import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:youtube_stemmer/model_downloader.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late Directory tempDir;
  late ModelDownloader downloader;
  final testModel = availableModels.first;

  setUp(() {
    mockDio = MockDio();
    tempDir = Directory.systemTemp.createTempSync('model_test');
    downloader = ModelDownloader(dio: mockDio, basePath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('isModelDownloaded returns true if file exists', () async {
    final modelPath = await downloader.getModelPath(testModel);
    File(modelPath).createSync(recursive: true);
    
    expect(await downloader.isModelDownloaded(testModel), isTrue);
  });

  test('isModelDownloaded returns false if file missing', () async {
    expect(await downloader.isModelDownloaded(testModel), isFalse);
  });

  test('downloadModel calls dio.download and renames file', () async {
    final modelPath = await downloader.getModelPath(testModel);
    final tempPath = '$modelPath.download';

    when(() => mockDio.download(
      any(),
      any(),
      cancelToken: any(named: 'cancelToken'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    )).thenAnswer((invocation) async {
      // Create the temp file
      File(tempPath).createSync(recursive: true);
      return Response(requestOptions: RequestOptions(path: ''));
    });

    await downloader.downloadModel(
      model: testModel,
      onProgress: (_) {},
    );

    expect(File(modelPath).existsSync(), isTrue);
    expect(File(tempPath).existsSync(), isFalse);
    
    verify(() => mockDio.download(
      testModel.url,
      tempPath,
      cancelToken: any(named: 'cancelToken'),
      onReceiveProgress: any(named: 'onReceiveProgress'),
    )).called(1);
  });
}
