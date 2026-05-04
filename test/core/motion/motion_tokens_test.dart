import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/motion/motion_tokens.dart';

void main() {
  group('MotionTokens', () {
    test('durations are in ascending order', () {
      expect(MotionTokens.quick.inMilliseconds,
          lessThan(MotionTokens.short.inMilliseconds));
      expect(MotionTokens.short.inMilliseconds,
          lessThan(MotionTokens.medium.inMilliseconds));
      expect(MotionTokens.medium.inMilliseconds,
          lessThan(MotionTokens.long.inMilliseconds));
    });

    test('pressedScale is between 0 and 1', () {
      expect(MotionTokens.pressedScale, greaterThan(0));
      expect(MotionTokens.pressedScale, lessThan(1));
    });

    test('staggerStep delay is non-negative', () {
      expect(MotionTokens.staggerStep.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('gentleSpring is a valid curve', () {
      expect(MotionTokens.gentleSpring, isA<Curve>());
    });

    test('standard easing is a valid curve', () {
      expect(MotionTokens.standard, isA<Curve>());
    });
  });

  group('RespectMotion', () {
    testWidgets('returns false when no ancestor provides reduced motion', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = RespectMotion.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      // Default should be false (no reduced motion).
      expect(result, isFalse);
    });
  });
}
