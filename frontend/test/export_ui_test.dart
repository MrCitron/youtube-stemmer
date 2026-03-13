import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/export_ui.dart';

void main() {
  testWidgets('ExportUI displays format dropdown and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExportUI(
          stemVolumes: {'vocals': 1.0},
          onExportZip: (_) {},
          onExportMix: (_) {},
        ),
      ),
    ));

    expect(find.text('EXPORT STEMS'), findsOneWidget);
    expect(find.text('WAV'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('Export ZIP'), findsOneWidget);
    expect(find.text('Mixdown'), findsOneWidget);
  });

  testWidgets('ExportUI shows progress indicator when processing', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExportUI(
          stemVolumes: {'vocals': 1.0},
          onExportZip: (_) {},
          onExportMix: (_) {},
          isProcessing: true,
          statusMessage: 'Converting...',
        ),
      ),
    ));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Converting...'), findsOneWidget);
  });
}
