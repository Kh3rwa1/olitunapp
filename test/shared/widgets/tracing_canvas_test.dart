import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/widgets/tracing_canvas.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/analytics/analytics_service.dart';

class MockAudioService extends AudioService {
  @override
  Future<void> playUrl(String url) async {}
}

class MockAnalyticsService implements LearningAnalyticsService {
  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {}

  @override
  Future<void> flushPending() async {}

  @override
  Future<void> logAdEvent(AdEvent event) async {}
}

void main() {
  testWidgets(
    'TracingCanvas renders custom outline grid lines and header labels',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const config = TracingConfig(
        glyph: 'ᱚ',
        strokes: [
          TracingStroke(
            id: 'stroke_1',
            order: 0,
            path: [TracingPoint(x: 0.1, y: 0.1), TracingPoint(x: 0.9, y: 0.9)],
          ),
        ],
        requiredCompletions: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioServiceProvider.overrideWithValue(MockAudioService()),
            learningAnalyticsServiceProvider.overrideWithValue(
              MockAnalyticsService(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: TracingCanvas(config: config)),
          ),
        ),
      );

      // Verify Title and Subtitle labels
      expect(find.text('Tracing practice — ᱚ'), findsOneWidget);
      expect(
        find.text('Trace the character guidelines accurately'),
        findsOneWidget,
      );
      expect(find.text('Mastery: 0/3'), findsOneWidget);

      // Verify presence of buttons
      expect(find.text('Show example'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    },
  );

  testWidgets('TracingCanvas resets state and allows example playbacks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const config = TracingConfig(
      glyph: 'ᱚ',
      strokes: [
        TracingStroke(
          id: 'stroke_1',
          order: 0,
          path: [TracingPoint(x: 0.1, y: 0.1), TracingPoint(x: 0.9, y: 0.9)],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(MockAudioService()),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockAnalyticsService(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TracingCanvas(config: config)),
        ),
      ),
    );

    // Click "Show example" button
    await tester.tap(find.text('Show example'));
    await tester.pump();

    // Pump animation ticks
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap reset button
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
  });
}
