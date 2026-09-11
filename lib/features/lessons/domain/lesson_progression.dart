import 'entities/lesson_entity.dart';

/// The learner-facing state of a lesson in a sequential learning path.
enum LessonProgressStatus { completed, current, locked }

/// Pure progression rules shared by the path UI and deep-link guard.
///
/// A lesson is available when every active lesson before it is complete.
/// Completed lessons stay available for review, including legacy progress that
/// may not form a contiguous prefix.
abstract final class LessonProgression {
  static List<LessonEntity> orderedActiveLessons(
    Iterable<LessonEntity> lessons,
  ) {
    final indexed = lessons.where((lesson) => lesson.isActive).indexed.toList();
    indexed.sort((left, right) {
      final byOrder = left.$2.order.compareTo(right.$2.order);
      return byOrder != 0 ? byOrder : left.$1.compareTo(right.$1);
    });
    return List<LessonEntity>.unmodifiable(
      indexed.map((entry) => entry.$2),
    );
  }

  static LessonProgressStatus statusFor({
    required List<LessonEntity> orderedLessons,
    required Set<String> completedLessonIds,
    required String lessonId,
  }) {
    final index = orderedLessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index < 0) return LessonProgressStatus.locked;
    if (completedLessonIds.contains(lessonId)) {
      return LessonProgressStatus.completed;
    }

    for (var previousIndex = 0; previousIndex < index; previousIndex++) {
      if (!completedLessonIds.contains(orderedLessons[previousIndex].id)) {
        return LessonProgressStatus.locked;
      }
    }
    return LessonProgressStatus.current;
  }

  static LessonEntity? blockingLesson({
    required List<LessonEntity> orderedLessons,
    required Set<String> completedLessonIds,
    required String lessonId,
  }) {
    final index = orderedLessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index <= 0) return null;

    for (var previousIndex = 0; previousIndex < index; previousIndex++) {
      final lesson = orderedLessons[previousIndex];
      if (!completedLessonIds.contains(lesson.id)) return lesson;
    }
    return null;
  }
}
