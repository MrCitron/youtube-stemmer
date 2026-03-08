import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/export_ui.dart';

void main() {
  testWidgets('ExportUI displays format dropdown and buttons', (WidgetTester tester) async {
    bool zipCalled = false;
    bool mixCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExportUI(
          stemVolumes: const {'bass': 1.0, 'drums': 1.0},
          onExportZip: (format) => zipCalled = true,
          onExportMix: (format) => mixCalled = true,
        ),
      ),
    ));

    expect(find.text('Export Options'), findsOneWidget);
    expect(find.text('WAV'), findsOneWidget);
    expect(find.text('Export ALL (ZIP)'), findsOneWidget);
    expect(find.text('Export Mixdown'), findsOneWidget);

    await tester.tap(find.text('Export ALL (ZIP)'));
    await tester.pump();
    expect(zipCalled, isTrue);

    await tester.tap(find.text('Export Mixdown'));
    await tester.pump();
    expect(mixCalled, isTrue);
  });

  testWidgets('ExportUI shows progress indicator when processing', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExportUI(
          stemVolumes: const {'bass': 1.0, 'drums': 1.0},
          onExportZip: (_) {},
          onExportMix: (_) {},
          isProcessing: true,
        ),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Export ALL (ZIP)'), findsNothing);
  });
}
