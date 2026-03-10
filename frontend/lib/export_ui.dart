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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXPORT STEMS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(2),
              child: SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(value: ExportFormat.wav, label: Text('WAV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ButtonSegment(value: ExportFormat.mp3, label: Text('MP3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: widget.isProcessing ? null : (v) {
                  setState(() => _selectedFormat = v.first);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isProcessing)
          Center(
            child: Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.statusMessage ?? 'Processing...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => widget.onExportZip(_selectedFormat),
                  icon: const Icon(Icons.folder_zip_outlined, size: 18),
                  label: const Text('Export ZIP'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => widget.onExportMix(_selectedFormat),
                  icon: const Icon(Icons.equalizer_rounded, size: 18),
                  label: const Text('Mixdown'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
