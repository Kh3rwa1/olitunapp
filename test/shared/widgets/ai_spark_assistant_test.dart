import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/widgets/ai_spark_assistant.dart';

void main() {
  testWidgets('AiSparkAssistant renders and responds to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiSparkAssistant(
            statusText: 'Generating audio…',
            subheadText: 'Hang tight…',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    // Initial render
    expect(find.text('Generating audio…'), findsOneWidget);
    expect(find.text('Hang tight…'), findsOneWidget);

    // Tap the widget
    await tester.tap(find.byType(AiSparkAssistant));
    await tester.pump(const Duration(milliseconds: 150));

    expect(tapped, isTrue);
  });

  testWidgets('AiSparkAssistant compact mode renders inline row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiSparkAssistant(statusText: 'Transcribing…', compact: true),
        ),
      ),
    );

    expect(find.text('Transcribing…'), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
  });
}
