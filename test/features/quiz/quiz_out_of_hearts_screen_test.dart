import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_out_of_hearts_screen.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/core/storage/hive_service.dart';
import '../../test_utils.dart';

class TestQuizSessionNotifier extends QuizSessionNotifier {
  bool resetCalled = false;

  @override
  void reset() {
    super.reset();
    resetCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockQuizId = 'test_quiz';
  final mockQuestions = [
    QuizQuestion(
      promptOlChiki: 'Q1',
      optionsLatin: ['A', 'B'],
      optionsOlChiki: ['A', 'B'],
    ),
  ];

  testWidgets('QuizOutOfHeartsScreen renders sad state and triggers reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final mockPrefs = await SharedPreferences.getInstance();

    final mockSessionNotifier = TestQuizSessionNotifier();

    await tester.pumpWidget(
      createTestableWidget(
        child: QuizOutOfHeartsScreen(
          score: 2,
          totalQuestions: 5,
          bonusStars: 4,
          incorrectQuestionIndices: const [0],
          questions: mockQuestions,
          quizId: mockQuizId,
        ),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizSessionNotifierProvider.overrideWith(() => mockSessionNotifier),
        ],
      ),
    );

    // Let any animations complete
    await tester.pump(const Duration(seconds: 1));

    // Verify UI components render
    expect(find.text('Out of Hearts!'), findsOneWidget);
    expect(find.textContaining('You answered 2/5 correctly'), findsOneWidget);
    expect(
      find.textContaining('earned 14 stars'),
      findsOneWidget,
    ); // 2 * 5 + 4 = 14
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Review Mistakes'), findsOneWidget);
    expect(find.text('Back to Quizzes'), findsOneWidget);

    // Tap Try Again
    await tester.tap(find.text('Try Again'));
    expect(mockSessionNotifier.resetCalled, isTrue);
  });

  testWidgets('QuizOutOfHeartsScreen golden test', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final mockPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      createTestableWidget(
        child: RepaintBoundary(
          child: QuizOutOfHeartsScreen(
            score: 2,
            totalQuestions: 5,
            bonusStars: 4,
            incorrectQuestionIndices: const [0],
            questions: mockQuestions,
            quizId: mockQuizId,
          ),
        ),
        overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
      await expectLater(
        find.byType(QuizOutOfHeartsScreen),
        matchesGoldenFile('../../goldens/quiz_out_of_hearts.png'),
      );
    }
  });
}
