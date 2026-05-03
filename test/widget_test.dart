import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme.light builds a valid Material 3 theme', (tester) async {
    final theme = AppTheme.lightTheme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
  });

  testWidgets('AppTheme.dark builds a valid Material 3 theme', (tester) async {
    final theme = AppTheme.darkTheme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('MaterialApp boots cleanly with AppTheme.light', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('Olitun'))),
      ),
    );
    expect(find.text('Olitun'), findsOneWidget);
  });

  testWidgets('Dark theme renders without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          appBar: null,
          body: SafeArea(child: Text('dark')),
        ),
      ),
    );
    expect(find.text('dark'), findsOneWidget);
  });
}
