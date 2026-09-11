import '../../quiz/domain/quiz_scoring_rules.dart';
import 'entities/lesson_entity.dart';

/// Validates the lesson context attached to a quiz route before progression is
/// recorded. This prevents a forged query parameter from completing an
/// unrelated lesson.
abstract final class LessonQuizProgression {
  static LessonEntity? linkedPassingLesson({
    required String? lessonId,
    required String quizId,
    required int score,
    required int totalQuestions,
    required Iterable<LessonEntity> Function() lessons,
  }) {
    final normalizedLessonId = lessonId?.trim();
    if (normalizedLessonId == null ||
        normalizedLessonId.isEmpty ||
        !QuizScoringRules.isPassing(score, totalQuestions)) {
      return null;
    }

    for (final lesson in lessons()) {
      if (lesson.id != normalizedLessonId) continue;
      if (_belongsToLesson(quizId, lesson)) return lesson;
      return null;
    }
    return null;
  }

  static bool _belongsToLesson(String quizId, LessonEntity lesson) {
    if (quizId == 'dynamic_quiz_${lesson.id}' ||
        quizId == 'listening_quiz_${lesson.id}') {
      return true;
    }
    return lesson.blocks.any((block) {
      if (block.type != 'quiz') return false;
      final linkedQuizId =
          block.data?['quizId'] as String? ??
          block.data?['quizRefId'] as String?;
      return linkedQuizId == quizId;
    });
  }
}
