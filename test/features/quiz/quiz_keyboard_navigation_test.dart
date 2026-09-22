import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_active_view.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_feedback_panel.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  final testQuestion = QuizQuestion(
    promptOlChiki: 'ᱚ',
    promptLatin: 'Select "o"',
    optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
    optionsLatin: ['o', 't', 'g', 'ng'],
  );

  final testQuiz = QuizModel(
    id: 'test_quiz',
    title: 'Test Quiz',
    questions: [testQuestion],
  );

  Widget host({
    required QuizSessionState state,
    required ValueChanged<int> onSelectAnswer,
    required VoidCallback onContinue,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QuizActiveView(
          quizId: 'test_quiz',
          quiz: testQuiz,
          state: state,
          question: testQuestion,
          onSelectAnswer: onSelectAnswer,
          onContinue: onContinue,
        ),
      ),
    );
  }

  testWidgets('ArrowDown cycles focus across options', (tester) async {
    await tester.pumpWidget(
      host(
        state: const QuizSessionState(),
        onSelectAnswer: (_) {},
        onContinue: () {},
      ),
    );
    await tester.pumpAndSettle();

    // Initially no option tile is focused
    var tiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .toList();
    expect(tiles.every((t) => !t.isFocused), isTrue);

    // Press ArrowDown -> focuses first option (index 0)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    tiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .toList();
    expect(tiles[0].isFocused, isTrue);
    expect(tiles[1].isFocused, isFalse);

    // Press ArrowDown again -> focuses second option (index 1)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    tiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .toList();
    expect(tiles[0].isFocused, isFalse);
    expect(tiles[1].isFocused, isTrue);

    // Press ArrowUp -> goes back to first option (index 0)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    tiles = tester
        .widgetList<QuizOptionTile>(find.byType(QuizOptionTile))
        .toList();
    expect(tiles[0].isFocused, isTrue);
  });

  testWidgets('Digit keys 1-4 directly select corresponding options', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      host(
        state: const QuizSessionState(),
        onSelectAnswer: (idx) => selected = idx,
        onContinue: () {},
      ),
    );
    await tester.pumpAndSettle();

    // Press 2 -> selects index 1
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(selected, equals(1));

    // Press 4 -> selects index 3
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    expect(selected, equals(3));
  });

  testWidgets('Enter submits focused option when unanswered', (tester) async {
    int? selected;
    await tester.pumpWidget(
      host(
        state: const QuizSessionState(),
        onSelectAnswer: (idx) => selected = idx,
        onContinue: () {},
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to option 2 (index 1)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    // Press Enter to submit
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, equals(1));
  });

  testWidgets('Enter on QuizFeedbackPanel triggers continue', (tester) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuizFeedbackPanel(
            isCorrect: true,
            correctOptionOlChiki: 'ᱚ',
            correctOptionLatin: 'o',
            onContinue: () => continued = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(continued, isTrue);
  });
}
