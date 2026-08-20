import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_screen.dart';
import 'package:itun/features/quiz/data/quiz_repository.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_question_card.dart';

void main() {
  testWidgets('Quiz flow: Load quiz, answer questions, see completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Explorer',
      'user_avatar_emoji': '👶',
      'user_avatar_color': 0,
      'show_onboarding': false,
    });
    final prefs = await SharedPreferences.getInstance();

    final dummyQuiz = QuizModel(
      id: 'test_quiz_1',
      title: 'Integration Quiz',
      questions: [
        QuizQuestion(
          promptOlChiki: 'ᱚ',
          promptLatin: 'O',
          optionsOlChiki: const ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
          optionsLatin: const ['O', 'T', 'G', 'NG'],
          audioUrl: '',
        ),
        QuizQuestion(
          promptOlChiki: 'ᱛ',
          promptLatin: 'T',
          optionsOlChiki: const ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
          optionsLatin: const ['O', 'T', 'G', 'NG'],
          correctIndex: 1,
          audioUrl: '',
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/quiz/test_quiz_1',
      routes: [
        GoRoute(
          path: '/quiz/:id',
          builder: (context, state) =>
              QuizScreen(quizId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          quizResultProvider(
            'test_quiz_1',
          ).overrideWith((ref) => AsyncValue.data(Right(dummyQuiz))),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Quiz title
    expect(find.text('Integration Quiz'), findsOneWidget);

    // Verify option tiles are present
    expect(find.byType(QuizOptionTile), findsNWidgets(4));

    // Determine currently displayed prompt for Q1
    final promptO = find.descendant(
      of: find.byType(QuizQuestionCard),
      matching: find.text('O'),
    );
    final isFirstQO = promptO.evaluate().isNotEmpty;
    final targetFirst = isFirstQO ? 'O' : 'T';
    final targetSecond = isFirstQO ? 'T' : 'O';

    // Tap matching option in QuizOptionTile
    await tester.tap(
      find.ancestor(
        of: find.text(targetFirst),
        matching: find.byType(QuizOptionTile),
      ),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify option tiles are present for Q2
    expect(find.byType(QuizOptionTile), findsNWidgets(4));

    // Tap matching option in QuizOptionTile for Q2
    await tester.tap(
      find.ancestor(
        of: find.text(targetSecond),
        matching: find.byType(QuizOptionTile),
      ),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify completion screen (trophy and pass indicator)
    expect(find.byType(QuizCompleteScreen), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text('Well Done!'), findsOneWidget);
  });
}
