import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_stemmer/main.dart';

void main() {
  testWidgets('Theme cycle test: system -> light -> dark -> system', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final MyAppState state = tester.state(find.byType(MyApp));
    
    // Initial state should be system (Auto)
    expect(state.getThemeMode(), ThemeMode.system);

    // Toggle to Light
    state.toggleTheme();
    await tester.pump();
    expect(state.getThemeMode(), ThemeMode.light);

    // Toggle to Dark
    state.toggleTheme();
    await tester.pump();
    expect(state.getThemeMode(), ThemeMode.dark);

    // Toggle back to System
    state.toggleTheme();
    await tester.pump();
    expect(state.getThemeMode(), ThemeMode.system);
  });
}
