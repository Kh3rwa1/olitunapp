import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/features/quiz/data/quiz_repository.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quiz flow: Load quiz, answer questions, see completion', (
    tester,
  ) async {
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
          quizFutureProvider(
            'test_quiz_1',
          ).overrideWith((ref) => Future.value(dummyQuiz)),
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

    // Verify first question
    expect(find.text('O'), findsWidgets); // Prompt and Option

    // Tap correct option (index 0 which is 'O')
    await tester.tap(find.text('O').last);
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify second question
    expect(find.text('T'), findsWidgets);

    // Tap correct option (index 1 which is 'T')
    await tester.tap(find.text('T').last);
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify completion screen (using score and total)
    expect(find.text('You scored 2 out of 2'), findsOneWidget);
  });
}
