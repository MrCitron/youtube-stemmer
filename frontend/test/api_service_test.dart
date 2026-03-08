import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:youtube_stemmer/api_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late ApiService apiService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    apiService = ApiService(baseUrl: 'http://localhost:8000', client: mockClient);
  });

  group('ApiService', () {
    test('healthCheck returns true when status code is 200 and body is ok', () async {
      when(() => mockClient.get(Uri.parse('http://localhost:8000/health')))
          .thenAnswer((_) async => http.Response(jsonEncode({'status': 'ok'}), 200));

      final result = await apiService.healthCheck();

      expect(result, isTrue);
    });

    test('healthCheck returns false when status code is not 200', () async {
      when(() => mockClient.get(Uri.parse('http://localhost:8000/health')))
          .thenAnswer((_) async => http.Response('Error', 500));

      final result = await apiService.healthCheck();

      expect(result, isFalse);
    });
  });
}
