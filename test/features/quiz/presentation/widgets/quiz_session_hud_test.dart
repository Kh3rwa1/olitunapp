import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_session_hud.dart';

void main() {
  group('QuizCountPill', () {
    testWidgets('renders current/total with a screen-reader label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuizCountPill(current: 2, total: 5)),
      );

      expect(find.text('2/5'), findsOneWidget);
      final semantics = tester.getSemantics(find.text('2/5'));
      expect(semantics.label, 'Quiz progress');
      expect(semantics.value, 'Question 2 of 5');
    });
  });

  group('QuizSessionHud', () {
    QuizSessionState stateOf(QuizSessionState base) => base;

    Widget hud(QuizSessionState state, {bool isDark = false}) => MaterialApp(
      home: Scaffold(
        body: QuizSessionHud(state: state, isDark: isDark),
      ),
    );

    testWidgets('shows hearts only when there is no combo streak', (
      tester,
    ) async {
      await tester.pumpWidget(hud(stateOf(const QuizSessionState(hearts: 2))));

      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      // No combo chips without a streak.
      expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
      expect(find.byIcon(Icons.bolt_rounded), findsNothing);
      expect(
        tester.getSemantics(find.byType(QuizSessionHud)).value,
        '2 hearts',
      );
    });

    testWidgets('adds combo and multiplier chips while a streak is live', (
      tester,
    ) async {
      await tester.pumpWidget(
        hud(
          stateOf(const QuizSessionState(comboStreak: 4, comboMultiplier: 2)),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(QuizSessionHud)).value,
        '3 hearts, 4 answer combo, 2 times multiplier',
      );
    });

    testWidgets('adapts chip styling to dark mode', (tester) async {
      await tester.pumpWidget(
        hud(stateOf(const QuizSessionState(hearts: 1)), isDark: true),
      );

      // Smoke: the dark variant builds and still renders the hearts chip.
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
