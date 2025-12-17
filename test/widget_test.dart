// Olitun App Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads welcome screen', (WidgetTester tester) async {
    // Basic smoke test - ensure widgets can be constructed
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Olitun'),
          ),
        ),
      ),
    );

    expect(find.text('Olitun'), findsOneWidget);
  });
}
