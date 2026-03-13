import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class HistoryItem {
  final int? id;
  final String title;
  final String url;
  final String directory;
  final List<String> stemNames;
  final Map<String, String> stemFiles;
  final double? bpm;
  final DateTime createdAt;

  HistoryItem({
    this.id,
    required this.title,
    required this.url,
    required this.directory,
    required this.stemNames,
    required this.stemFiles,
    this.bpm,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'directory': directory,
      'stemNames': jsonEncode(stemNames),
      'stemFiles': jsonEncode(stemFiles),
      'bpm': bpm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      title: map['title'],
      url: map['url'],
      directory: map['directory'],
      stemNames: List<String>.from(jsonDecode(map['stemNames'])),
      stemFiles: Map<String, String>.from(jsonDecode(map['stemFiles'])),
      bpm: map['bpm']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class HistoryService {
  static Database? _database;
  static const String tableName = 'history';
  static const String urlHistoryTable = 'url_history';
  static const String settingsTable = 'settings';
  final String? dbPath;

  HistoryService({this.dbPath});

  Future<Database> get database async {
    if (_database != null && dbPath == null) return _database!;
    final db = await _initDatabase();
    if (dbPath == null) _database = db;
    return db;
  }

  Future<Database> _initDatabase() async {
    String path;
    if (dbPath != null) {
      path = dbPath!;
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      path = join(appSupportDir.path, 'youtube_stemmer.db');
    }

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT,
            directory TEXT,
            stemNames TEXT,
            stemFiles TEXT,
            bpm REAL,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $urlHistoryTable (
            url TEXT PRIMARY KEY,
            title TEXT,
            timestamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $settingsTable (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN bpm REAL');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $urlHistoryTable (
              url TEXT PRIMARY KEY,
              title TEXT,
              timestamp TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $settingsTable (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      },
    );
  }

  // --- History Table ---

  Future<int> insertItem(HistoryItem item) async {
    final db = await database;
    return await db.insert(tableName, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HistoryItem>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => HistoryItem.fromMap(maps[i]));
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateItemTitle(int id, String newTitle) async {
    final db = await database;
    return await db.update(
      tableName,
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- URL History Table ---

  Future<void> insertUrlHistory(String url, String title) async {
    final db = await database;
    await db.insert(
      urlHistoryTable,
      {
        'url': url,
        'title': title,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Maintain only top 10 most recent
    final all = await db.query(urlHistoryTable, orderBy: 'timestamp DESC');
    if (all.length > 10) {
      final toDelete = all.sublist(10);
      for (var row in toDelete) {
        await db.delete(urlHistoryTable, where: 'url = ?', whereArgs: [row['url']]);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getUrlHistory() async {
    final db = await database;
    return await db.query(urlHistoryTable, orderBy: 'timestamp DESC');
  }

  // --- Settings ---

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
