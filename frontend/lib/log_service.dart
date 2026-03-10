import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>([]);

  void add(String message) {
    final timestamp = DateTime.now().toString().split('.').first.split(' ').last;
    logs.value = [...logs.value, '[$timestamp] $message'];
    debugPrint('[$timestamp] $message');
  }

  void clear() {
    logs.value = [];
  }

  String get allLogs => logs.value.join('\n');
}
