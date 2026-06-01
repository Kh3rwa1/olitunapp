import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import 'package:itun/core/storage/hive_service.dart';

class MockAudioService extends Mock implements AudioService {
  @override
  Future<void> playUrl(String url) async {}
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final mockQuiz = QuizModel(id: 'quiz_123', title: 'Alphabet Quiz 1');

  final mockLessons = [
    const LessonEntity(
      id: 'lesson_1',
      categoryId: 'cat_1',
      titleOlChiki: 'ᱛᱤ',
      titleLatin: 'Ti',
      blocks: [
        LessonBlockEntity(
          type: 'quiz',
          textOlChiki: '',
          textLatin: '',
          data: {'quizId': 'quiz_123'},
        ),
      ],
    ),
  ];

  final mockLessonsEmptyQuizId = [
    const LessonEntity(
      id: 'lesson_1',
      categoryId: 'cat_1',
      titleOlChiki: 'ᱛᱤ',
      titleLatin: 'Ti',
      blocks: [
        LessonBlockEntity(
          type: 'quiz',
          textOlChiki: '',
          textLatin: '',
          data: {}, // empty quiz ID
        ),
      ],
    ),
  ];

  final mockLessonsMissingQuiz = [
    const LessonEntity(
      id: 'lesson_1',
      categoryId: 'cat_1',
      titleOlChiki: 'ᱛᱤ',
      titleLatin: 'Ti',
      blocks: [
        LessonBlockEntity(
          type: 'quiz',
          textOlChiki: '',
          textLatin: '',
          data: {'quizId': 'quiz_missing'},
        ),
      ],
    ),
  ];

  testWidgets(
    'Happy path: active quiz CTA renders and navigates to quiz route',
    (tester) async {
      final mockAudioService = MockAudioService();

      final router = GoRouter(
        initialLocation: '/lesson/lesson_1',
        routes: [
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => const LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
          GoRoute(
            path: '/quiz/:quizId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Quiz Runner Screen: ${state.pathParameters['quizId']}',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mockLessons),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
            quizzesByIdProvider.overrideWithValue(
              AsyncValue.data({'quiz_123': mockQuiz}),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the celebratory quiz card CTA renders
      expect(find.text('Ready to test yourself?'), findsOneWidget);
      expect(
        find.text(
          'Great job! Take "Alphabet Quiz 1" now to test your knowledge.',
        ),
        findsOneWidget,
      );
      expect(find.text('TAKE THE QUIZ'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap TAKE THE QUIZ and assert routing
      await tester.ensureVisible(find.text('TAKE THE QUIZ'));
      await tester.tap(find.text('TAKE THE QUIZ'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz Runner Screen: quiz_123'), findsOneWidget);
    },
  );

  testWidgets(
    'Graceful absence: null or empty quiz ID renders SizedBox.shrink()',
    (tester) async {
      final mockAudioService = MockAudioService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mockLessonsEmptyQuizId),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
            quizzesByIdProvider.overrideWithValue(
              AsyncValue.data({'quiz_123': mockQuiz}),
            ),
          ],
          child: const MaterialApp(
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the screen is empty (SizedBox.shrink() rendered)
      expect(find.text('Ready to test yourself?'), findsNothing);
      expect(find.text('TAKE THE QUIZ'), findsNothing);
    },
  );

  testWidgets(
    'Graceful absence: missing quiz ID not in provider renders SizedBox.shrink()',
    (tester) async {
      final mockAudioService = MockAudioService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mockLessonsMissingQuiz),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
            quizzesByIdProvider.overrideWithValue(
              AsyncValue.data({'quiz_123': mockQuiz}),
            ),
          ],
          child: const MaterialApp(
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the screen is empty (SizedBox.shrink() rendered)
      expect(find.text('Ready to test yourself?'), findsNothing);
      expect(find.text('TAKE THE QUIZ'), findsNothing);
    },
  );

  testWidgets(
    'Dismiss-in-place: tapping "Skip for now" collapses the card, user remains on page, and screen does not pop',
    (tester) async {
      final mockAudioService = MockAudioService();
      bool didPop = false;

      final router = GoRouter(
        initialLocation: '/lesson/lesson_1',
        routes: [
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => const LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
        ],
        observers: [
          _MockNavigatorObserver(
            onPop: () {
              didPop = true;
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mockLessons),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
            quizzesByIdProvider.overrideWithValue(
              AsyncValue.data({'quiz_123': mockQuiz}),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the celebratory quiz card CTA renders initially
      expect(find.text('Ready to test yourself?'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap "Skip for now"
      await tester.ensureVisible(find.text('Skip for now'));
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Verify card has collapsed to SizedBox.shrink()
      expect(find.text('Ready to test yourself?'), findsNothing);
      expect(find.text('Skip for now'), findsNothing);

      // Assert that we did NOT pop the screen
      expect(didPop, isFalse);
      expect(find.byType(LessonBlockDetailScreen), findsOneWidget);
    },
  );
}

class _MockNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPop;

  _MockNavigatorObserver({required this.onPop});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop();
  }
}
