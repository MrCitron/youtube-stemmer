import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/main.dart';

void main() {
  testWidgets('Should show initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MyHomePage(title: 'YouTube Stemmer'),
    ));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Process YouTube'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Load Local Stems'), findsOneWidget);
  });
}
