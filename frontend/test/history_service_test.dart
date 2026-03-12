import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/history_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('HistoryService Tests', () {
    late HistoryService service;

    setUp(() {
      service = HistoryService(dbPath: inMemoryDatabasePath);
    });

    test('url_history table creation and data handling', () async {
      // Test URL history insertion
      await service.insertUrlHistory('https://youtube.com/watch?v=test1', 'Test Video 1');
      await service.insertUrlHistory('https://youtube.com/watch?v=test2', 'Test Video 2');

      final history = await service.getUrlHistory();
      
      expect(history.length, 2);
      expect(history[0]['url'], 'https://youtube.com/watch?v=test2');
      expect(history[0]['title'], 'Test Video 2');
      expect(history[1]['url'], 'https://youtube.com/watch?v=test1');
      expect(history[1]['title'], 'Test Video 1');
    });

    test('history table title update', () async {
      final item = HistoryItem(
        title: 'Original Title',
        url: 'https://test.com',
        directory: '/tmp',
        stemNames: ['vocals'],
        stemFiles: {'vocals': 'vocals.wav'},
        createdAt: DateTime.now(),
      );

      final id = await service.insertItem(item);
      expect(id, isNotNull);

      // Update title
      await service.updateItemTitle(id, 'Updated Title');

      final items = await service.getAllItems();
      final updatedItem = items.firstWhere((element) => element.id == id);
      expect(updatedItem.title, 'Updated Title');
    });
  });
}
