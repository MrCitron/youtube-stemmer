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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final path = join(appSupportDir.path, 'youtube_stemmer.db');

    return await openDatabase(
      path,
      version: 2,
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN bpm REAL');
        }
      },
    );
  }

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
}
