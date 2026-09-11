import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

class _QuizzesNotifier extends QuizzesNotifier {
  _QuizzesNotifier(this.initial);

  final AsyncValue<List<QuizModel>> initial;

  @override
  AsyncValue<List<QuizModel>> build() => initial;
}

class _RecordingStatsNotifier extends UserStatsNotifier {
  final completedLessonIds = <String>[];
  String? completedCategoryId;
  int? completedEstimatedMinutes;

  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    ),
  );

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {}

  @override
  Future<void> addStars(int count) async {}

  @override
  Future<void> completeLesson(
    String lessonId, {
    String? categoryId,
    int estimatedMinutes = 5,
  }) async {
    completedLessonIds.add(lessonId);
    completedCategoryId = categoryId;
    completedEstimatedMinutes = estimatedMinutes;
  }
}

class _MistakeNotifier extends MistakeNotifier {
  @override
  List<MistakeItem> build() => const [];

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {}

  @override
  Future<void> masterMistake({
    required String quizId,
    required int questionIndex,
  }) async {}

  @override
  Future<void> syncFromBackend() async {}
}

class _Analytics extends Mock implements LearningAnalyticsService {
  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {}
}

void main() {
  testWidgets('passing a linked quiz completes its lesson once', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final statsNotifier = _RecordingStatsNotifier();
    final quiz = QuizModel(
      id: 'lesson_quiz',
      categoryId: 'category_1',
      title: 'Lesson Quiz',
      questions: [
        QuizQuestion(
          promptOlChiki: 'ᱚ',
          promptLatin: 'Choose the sound',
          optionsOlChiki: const ['a', 'e'],
          optionsLatin: const ['a', 'e'],
          correctIndex: 0,
        ),
      ],
    );
    const lesson = LessonEntity(
      id: 'lesson_1',
      categoryId: 'category_1',
      titleOlChiki: 'One',
      titleLatin: 'Lesson One',
      estimatedMinutes: 8,
      blocks: [
        LessonBlockEntity(
          type: 'quiz',
          data: {'quizId': 'lesson_quiz'},
        ),
      ],
    );

    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(
          quizId: 'lesson_quiz',
          lessonId: 'lesson_1',
        ),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          quizzesProvider.overrideWith(
            () => _QuizzesNotifier(AsyncValue.data([quiz])),
          ),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data([lesson]),
          ),
          userStatsProvider.overrideWith(() => statsNotifier),
          mistakeProvider.overrideWith(_MistakeNotifier.new),
          learningAnalyticsServiceProvider.overrideWithValue(_Analytics()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(statsNotifier.completedLessonIds, ['lesson_1']);
    expect(statsNotifier.completedCategoryId, 'category_1');
    expect(statsNotifier.completedEstimatedMinutes, 8);
  });
}
