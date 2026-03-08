import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'model_downloader.dart';

class ModelDownloadDialog extends StatefulWidget {
  final AppModel model;
  const ModelDownloadDialog({super.key, required this.model});

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  final ModelDownloader _downloader = ModelDownloader();
  CancelToken? _cancelToken;
  double _progress = 0;
  late String _status;
  bool _isDownloading = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _status = 'The ${widget.model.name} AI model (~300MB) is required for stemming. Would you like to download it now?';
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasStarted = true;
      _status = 'Downloading ${widget.model.name}...';
      _cancelToken = CancelToken();
    });

    try {
      await _downloader.downloadModel(
        model: widget.model,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
            });
          }
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Success
      }
    } catch (e) {
      if (mounted) {
        if (CancelToken.isCancel(e as DioException)) {
          setState(() {
            _isDownloading = false;
            _hasStarted = false;
            _status = 'Download cancelled.';
          });
        } else {
          setState(() {
            _isDownloading = false;
            _status = 'Error: $e';
          });
        }
      }
    } finally {
      _cancelToken = null;
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Required: ${widget.model.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_status),
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('${(_progress * 100).toStringAsFixed(1)}%'),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading && !_hasStarted) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Download'),
          ),
        ] else if (_isDownloading) ...[
          TextButton(
            onPressed: _cancelDownload,
            child: const Text('Cancel'),
          ),
        ] else ...[
          // Error or cancelled state
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}
