import '../../profile/domain/entities/user_stats_entity.dart';
import '../../../shared/models/content_models.dart';

class LessonQuizRecommendation {
  const LessonQuizRecommendation({
    required this.quiz,
    required this.reason,
    required this.isRetake,
  });

  final QuizModel quiz;
  final String reason;
  final bool isRetake;
}

class LessonQuizRecommender {
  const LessonQuizRecommender._();

  static LessonQuizRecommendation? recommend({
    required ContentItem lesson,
    required List<QuizModel> quizzes,
    UserStatsEntity? stats,
  }) {
    final activeQuizzes = quizzes.where(_isPlayable).toList();
    if (activeQuizzes.isEmpty) return null;

    final explicitQuizIds = lesson.blocks
        .whereType<QuizBlock>()
        .map((block) => block.quizId.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    for (final quizId in explicitQuizIds) {
      final quiz = activeQuizzes.where((quiz) => quiz.id == quizId).firstOrNull;
      if (quiz != null) {
        return LessonQuizRecommendation(
          quiz: quiz,
          reason: 'This quiz is attached to the lesson you just completed.',
          isRetake: _hasTakenQuiz(stats, quiz.id),
        );
      }
    }

    final lessonCategory = _categoryKey(lesson.categoryId);
    if (lessonCategory.isEmpty) return null;

    final categoryMatches =
        activeQuizzes
            .where(
              (quiz) => _categoryKey(quiz.categoryId ?? '') == lessonCategory,
            )
            .toList()
          ..sort((a, b) {
            final aTaken = _hasTakenQuiz(stats, a.id);
            final bTaken = _hasTakenQuiz(stats, b.id);
            if (aTaken != bTaken) return aTaken ? 1 : -1;

            final levelCompare = _levelRank(
              a.level,
            ).compareTo(_levelRank(b.level));
            if (levelCompare != 0) return levelCompare;
            return a.order.compareTo(b.order);
          });

    final quiz = categoryMatches.firstOrNull;
    if (quiz == null) return null;

    return LessonQuizRecommendation(
      quiz: quiz,
      reason: quiz.categoryId == lesson.categoryId
          ? 'A quick quiz is ready for this lesson category.'
          : 'A related quiz is ready for this lesson.',
      isRetake: _hasTakenQuiz(stats, quiz.id),
    );
  }

  static bool _isPlayable(QuizModel quiz) {
    return quiz.isActive && quiz.questions.isNotEmpty;
  }

  static bool _hasTakenQuiz(UserStatsEntity? stats, String quizId) {
    if (stats == null) return false;
    return stats.quizHistory.keys.any(
      (key) => key == quizId || key.startsWith('$quizId@'),
    );
  }

  static int _levelRank(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 0;
      case 'intermediate':
        return 1;
      case 'advanced':
        return 2;
      default:
        return 0;
    }
  }

  static String _categoryKey(String categoryId) {
    final lower = categoryId.trim().toLowerCase();
    if (lower.isEmpty) return '';
    if (lower.contains('alphabet') || lower.contains('letter')) {
      return 'alphabets';
    }
    if (lower.contains('number')) return 'numbers';
    if (lower.contains('word') ||
        lower.contains('vocab') ||
        lower == 'cat_vocab') {
      return 'vocabulary';
    }
    if (lower.contains('sentence') ||
        lower.contains('phrase') ||
        lower == 'cat_sentences') {
      return 'sentences';
    }
    if (lower.contains('rhyme') || lower.contains('bakhed')) return 'rhymes';
    return lower;
  }
}
