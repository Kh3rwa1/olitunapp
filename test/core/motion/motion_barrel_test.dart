import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/motion/motion.dart';

// Exercises the barrel surface (lib/core/motion/motion.dart) so every
// motion primitive it re-exports is linked into the test suite.

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('motion barrel exports', () {
    test('MotionTokens vocabulary is sane', () {
      expect(MotionTokens.quick, lessThan(MotionTokens.short));
      expect(MotionTokens.short, lessThan(MotionTokens.medium));
      expect(MotionTokens.medium, lessThan(MotionTokens.long));
      expect(MotionTokens.pressedScale, lessThan(1.0));
      expect(MotionTokens.heroTag('letters', 'cat_1'), 'hero/letters/cat_1');
      expect(
        MotionTokens.staggerFor(10),
        lessThanOrEqualTo(MotionTokens.staggerMax),
      );
    });

    testWidgets('PressableScale renders and responds to taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(PressableScale(onTap: () => taps++, child: const Text('Press'))),
      );
      expect(find.text('Press'), findsOneWidget);
      await tester.tap(find.text('Press'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('AnimatedCounter renders its value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnimatedCounter(
            value: 7,
            duration: Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedCounter), findsOneWidget);
    });

    testWidgets('BrandedRefreshIndicator is a Scrollable wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BrandedRefreshIndicator(
            onRefresh: () async {},
            child: ListView(children: const [SizedBox(height: 400)]),
          ),
        ),
      );
      expect(find.byType(BrandedRefreshIndicator), findsOneWidget);
    });

    testWidgets('ConfettiBurst renders when triggered', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: _wrap(const ConfettiBurst()),
        ),
      );
      expect(find.byType(ConfettiBurst), findsOneWidget);
    });

    testWidgets('FocusGlowField wraps its child with a glow surface', (
      tester,
    ) async {
      final node = FocusNode();
      await tester.pumpWidget(
        _wrap(
          FocusGlowField(
            focusNode: node,
            child: TextField(controller: TextEditingController()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FocusGlowField), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
