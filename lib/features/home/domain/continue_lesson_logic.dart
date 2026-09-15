import '../../categories/domain/entities/category_entity.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import '../../lessons/domain/lesson_progression.dart';

/// Pure logic for selecting the next playable lesson for the learner.
///
/// Guarantees:
/// 1. Never returns a locked lesson.
/// 2. If [lastOpenedLessonId] is an unlocked, incomplete, active lesson, resumes it.
/// 3. If [lastOpenedLessonId] is locked, returns its earliest incomplete
///    prerequisite (blocking lesson), starting what is not finished.
/// 4. Otherwise, selects the next unlocked, incomplete active lesson in curriculum
///    sequence across available categories.
/// 5. Returns null only when every active lesson across all categories is completed.
LessonEntity? continueLessonFor({
  required List<LessonEntity> lessons,
  required Set<String> completedLessonIds,
  String? lastOpenedLessonId,
  List<CategoryEntity>? categories,
}) {
  if (lessons.isEmpty) return null;

  final categoryCache = <String, List<LessonEntity>>{};
  List<LessonEntity> getOrderedCategoryLessons(String categoryId) {
    return categoryCache.putIfAbsent(
      categoryId,
      () => LessonProgression.orderedActiveLessons(
        lessons.where((l) => l.categoryId == categoryId),
      ),
    );
  }

  // 1. Try to resume the last opened lesson, or start its blocking prerequisite
  final normalizedLastOpened = lastOpenedLessonId?.trim();
  if (normalizedLastOpened != null && normalizedLastOpened.isNotEmpty) {
    final target =
        lessons.where((l) => l.id == normalizedLastOpened).firstOrNull;
    if (target != null &&
        target.isActive &&
        !completedLessonIds.contains(target.id)) {
      final categoryLessons = getOrderedCategoryLessons(target.categoryId);
      final status = LessonProgression.statusFor(
        orderedLessons: categoryLessons,
        completedLessonIds: completedLessonIds,
        lessonId: target.id,
      );

      if (status != LessonProgressStatus.locked) {
        return target;
      }

      // The target is locked: resolve to its unfinished blocker in this category
      final blocker = LessonProgression.blockingLesson(
        orderedLessons: categoryLessons,
        completedLessonIds: completedLessonIds,
        lessonId: target.id,
      );
      if (blocker != null &&
          blocker.isActive &&
          !completedLessonIds.contains(blocker.id)) {
        return blocker;
      }
    }
  }

  // 2. Sequential curriculum progression across ordered active categories
  if (categories != null && categories.isNotEmpty) {
    final sortedCategories = List<CategoryEntity>.from(categories)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final cat in sortedCategories) {
      if (!cat.isActive) continue;
      final catLessons = getOrderedCategoryLessons(cat.id);
      for (final lesson in catLessons) {
        if (!completedLessonIds.contains(lesson.id)) {
          return lesson;
        }
      }
    }
  }

  // 3. Fallback traversal by category appearance in lessons
  final seenCategories = <String>{};
  for (final lesson in lessons) {
    if (!lesson.isActive) continue;
    if (seenCategories.add(lesson.categoryId)) {
      final catLessons = getOrderedCategoryLessons(lesson.categoryId);
      for (final candidate in catLessons) {
        if (!completedLessonIds.contains(candidate.id)) {
          return candidate;
        }
      }
    }
  }

  return null;
}
