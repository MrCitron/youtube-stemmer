import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  LogEntry(this.message, this.level) : timestamp = DateTime.now();

  @override
  String toString() {
    final timeStr = timestamp.toString().split('.').first.split(' ').last;
    return '[$timeStr] [${level.name.toUpperCase()}] $message';
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final ValueNotifier<List<LogEntry>> entries = ValueNotifier<List<LogEntry>>([]);

  void add(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(message, level);
    entries.value = [...entries.value, entry];
    debugPrint(entry.toString());
  }

  void debug(String message) => add(message, level: LogLevel.debug);
  void info(String message) => add(message, level: LogLevel.info);
  void warn(String message) => add(message, level: LogLevel.warn);
  void error(String message) => add(message, level: LogLevel.error);

  void clear() {
    entries.value = [];
  }

  String get allLogs => entries.value.map((e) => e.toString()).join('\n');
}
