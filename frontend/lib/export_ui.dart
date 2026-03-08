import 'package:flutter/material.dart';

enum ExportFormat { wav, mp3 }

class ExportUI extends StatefulWidget {
  final Map<String, double> stemVolumes;
  final Function(ExportFormat format) onExportZip;
  final Function(ExportFormat format) onExportMix;
  final bool isProcessing;
  final String? statusMessage;

  const ExportUI({
    super.key,
    required this.stemVolumes,
    required this.onExportZip,
    required this.onExportMix,
    this.isProcessing = false,
    this.statusMessage,
  });

  @override
  State<ExportUI> createState() => _ExportUIState();
}

class _ExportUIState extends State<ExportUI> {
  ExportFormat _selectedFormat = ExportFormat.wav;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Format: '),
                DropdownButton<ExportFormat>(
                  value: _selectedFormat,
                  items: ExportFormat.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: widget.isProcessing
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedFormat = v);
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.isProcessing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(widget.statusMessage ?? 'Processing...'),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => widget.onExportZip(_selectedFormat),
                    icon: const Icon(Icons.archive),
                    label: const Text('Export ALL (ZIP)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => widget.onExportMix(_selectedFormat),
                    icon: const Icon(Icons.merge),
                    label: const Text('Export Mixdown'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
