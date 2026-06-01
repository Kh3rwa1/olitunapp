import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_recommender.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  final question = QuizQuestion(
    promptOlChiki: 'ᱚ',
    optionsOlChiki: ['ᱚ', 'ᱟ'],
    optionsLatin: ['a', 'aa'],
  );

  QuizModel quiz(
    String id, {
    String? categoryId = 'alphabets',
    int order = 0,
    bool isActive = true,
    String level = 'beginner',
  }) {
    return QuizModel(
      id: id,
      categoryId: categoryId,
      title: id,
      order: order,
      isActive: isActive,
      level: level,
      questions: [question],
    );
  }

  ContentItem lesson({
    String categoryId = 'alphabets',
    List<ContentBlock> blocks = const [],
  }) {
    return ContentItem(
      id: 'lesson_1',
      kind: ContentKind.lesson,
      categoryId: categoryId,
      title: 'Lesson 1',
      blocks: blocks,
      updatedAt: DateTime(2026, 5, 29),
    );
  }

  test('prefers an explicit quiz block attached to the lesson', () {
    final recommendation = LessonQuizRecommender.recommend(
      lesson: lesson(
        blocks: const [QuizBlock(id: 'quiz_block', order: 0, quizId: 'q2')],
      ),
      quizzes: [quiz('q1'), quiz('q2')],
    );

    expect(recommendation?.quiz.id, 'q2');
    expect(recommendation?.isRetake, isFalse);
  });

  test('falls back to the first untaken active quiz in the same category', () {
    const stats = UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {
        'q1': QuizResultEntity(
          quizId: 'q1',
          score: 1,
          totalQuestions: 1,
          completedAt: '2026-05-29T00:00:00.000',
        ),
      },
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    );

    final recommendation = LessonQuizRecommender.recommend(
      lesson: lesson(),
      quizzes: [
        quiz('inactive', isActive: false),
        quiz('empty').copyWith(questions: const []),
        quiz('q1'),
        quiz('q2', order: 1),
      ],
      stats: stats,
    );

    expect(recommendation?.quiz.id, 'q2');
    expect(recommendation?.isRetake, isFalse);
  });

  test('matches normalized vocabulary category ids', () {
    final recommendation = LessonQuizRecommender.recommend(
      lesson: lesson(categoryId: 'words'),
      quizzes: [quiz('vocab_quiz', categoryId: 'cat_vocab')],
    );

    expect(recommendation?.quiz.id, 'vocab_quiz');
  });
}
