import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_bento_stats.dart';

Widget _wrap({required bool isDark}) => MaterialApp(
  theme: isDark ? ThemeData.dark() : ThemeData.light(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: QuizCompleteBentoStats(
        isDark: isDark,
        score: 3,
        totalQuestions: 5,
        percentage: 60,
        isPassing: false,
        totalStars: 12,
        bestCombo: 4,
      ),
    ),
  ),
);

void main() {
  testWidgets('renders all four bento stat cards', (tester) async {
    await tester.pumpWidget(_wrap(isDark: false));
    await tester.pumpAndSettle();

    expect(find.text('Score'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Stars Earned'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('Max Combo'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    // Accuracy below the passing mark uses the error accent.
    expect(find.byIcon(Icons.track_changes_rounded), findsOneWidget);
  });

  testWidgets('renders the dark variant without overflowing', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(isDark: true));
    await tester.pumpAndSettle();

    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
  });
}
