import 'package:flutter/material.dart';
import 'history_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class HistoryScreen extends StatefulWidget {
  final Function(HistoryItem) onSelect;

  const HistoryScreen({super.key, required this.onSelect});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _items = [];
  Map<int, String> _itemSizes = {};
  bool _isLoading = true;
  String _totalSize = '0 B';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _historyService.getAllItems();
    final sizes = <int, String>{};
    int totalBytes = 0;

    for (var item in items) {
      if (item.id != null) {
        final bytes = await _getDirSize(item.directory);
        sizes[item.id!] = _formatBytes(bytes);
        totalBytes += bytes;
      }
    }

    if (mounted) {
      setState(() {
        _items = items;
        _itemSizes = sizes;
        _totalSize = _formatBytes(totalBytes);
        _isLoading = false;
      });
    }
  }

  Future<int> _getDirSize(String path) async {
    int totalSize = 0;
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating size for $path: $e');
    }
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _deleteItem(HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Entry?'),
        content: const Text('This will also delete the audio files on disk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      if (item.id != null) {
        await _historyService.deleteItem(item.id!);
        // Delete directory (only if it's in our stems folder - be careful with local imports!)
        if (!item.url.startsWith('local:')) {
          final dir = Directory(item.directory);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
        _loadHistory();
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all history entries and processed files (excluding local imports). This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      for (var item in _items) {
        if (item.id != null) {
          await _historyService.deleteItem(item.id!);
          if (!item.url.startsWith('local:')) {
            final dir = Directory(item.directory);
            if (await dir.exists()) {
              await dir.delete(recursive: true);
            }
          }
        }
      }
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing History'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _clearAllHistory,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Total Size on Disk: $_totalSize', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('No history items found.'))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final size = _itemSizes[item.id] ?? '...';
                            final isLocal = item.url.startsWith('local:');

                            return ListTile(
                              leading: Icon(isLocal ? Icons.folder : Icons.cloud_download),
                              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${item.createdAt.toString().split('.').first} • $size'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item),
                              ),
                              onTap: () {
                                widget.onSelect(item);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
