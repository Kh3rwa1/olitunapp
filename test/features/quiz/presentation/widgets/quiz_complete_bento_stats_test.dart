import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_bento_stats.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

Widget _wrap({required bool isDark}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('uses 4 columns on wide desktop screens and 2 on mobile', (
    tester,
  ) async {
    // Narrow screen (mobile, 400px)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(isDark: false));
    await tester.pumpAndSettle();

    GridView grid = tester.widget<GridView>(find.byType(GridView));
    SliverGridDelegateWithFixedCrossAxisCount delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    // Wide screen (desktop, 900px)
    tester.view.physicalSize = const Size(900, 800);
    await tester.pump();
    await tester.pumpAndSettle();

    grid = tester.widget<GridView>(find.byType(GridView));
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
  });
}
