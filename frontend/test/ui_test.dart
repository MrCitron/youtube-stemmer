import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/main.dart';

void main() {
  testWidgets('Should show initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('YouTube Stemmer'), findsAtLeast(1));
    expect(find.text('Process Video'), findsOneWidget);
    expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    expect(find.text('Paste YouTube URL here...'), findsOneWidget);
  });
}
