import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_providers.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/models/content_item_extensions.dart';
import '../../../../shared/repositories/content_repository.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final lessonNotifierProvider =
    StateNotifierProvider<LessonNotifier, AsyncValue<List<LessonEntity>>>(
      (ref) => LessonNotifier(ref.watch(lessonRepositoryProvider), ref: ref),
    );

final lessonsByCategoryProvider =
    Provider.family<AsyncValue<List<LessonEntity>>, String>((ref, categoryId) {
      final lessonsAsync = ref.watch(
        contentListProvider((ContentKind.lesson, categoryId)),
      );
      return lessonsAsync.when(
        data: (items) => AsyncValue.data(
          items.map((item) => item.toLessonEntity()).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });

class LessonNotifier extends StateNotifier<AsyncValue<List<LessonEntity>>> {
  final LessonRepository _repository;
  final Ref? _ref;

  LessonNotifier(this._repository, {Ref? ref})
    : _ref = ref,
      super(const AsyncValue.loading()) {
    loadLessons();
  }

  Future<void> loadLessons() async {
    if (!mounted) return;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    final result = await _repository.getLessons();
    if (!mounted) return;
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (lessons) => state = AsyncValue.data(_deduplicateLessons(lessons)),
    );
  }

  List<LessonEntity> _deduplicateLessons(List<LessonEntity> lessons) {
    final seenIds = <String>{};
    final seenTitles = <String>{};
    final unique = <LessonEntity>[];

    for (final lesson in lessons) {
      if (seenIds.contains(lesson.id)) continue;
      final normTitle = lesson.titleLatin.trim().toLowerCase();
      // Combine title and category to differentiate same titles in different categories
      final key = '${lesson.categoryId}_$normTitle';
      if (seenTitles.contains(key)) continue;

      seenIds.add(lesson.id);
      seenTitles.add(key);
      unique.add(lesson);
    }
    return unique;
  }

  Future<void> refresh() => loadLessons();

  Future<void> trackLessonStarted(
    LessonEntity lesson, {
    bool alreadyCompleted = false,
    String? scriptMode,
  }) async {
    final ref = _ref;
    if (ref == null) return;

    await ref
        .read(learningAnalyticsServiceProvider)
        .track(
          LearningAnalyticsEvents.lessonStarted,
          source: 'lesson_detail',
          sourceId: lesson.id,
          scriptMode: scriptMode,
          metadata: {
            'categoryId': lesson.categoryId,
            'estimatedMinutes': lesson.estimatedMinutes,
            'alreadyCompleted': alreadyCompleted,
          },
        );
  }

  Future<void> addLesson(LessonEntity lesson) async {
    final result = await _repository.createLesson(lesson);
    await result.fold<Future<void>>((failure) async {
      state = AsyncValue.error(failure.message, StackTrace.current);
      throw StateError(failure.message);
    }, (_) => loadLessons());
  }

  Future<void> updateLesson(LessonEntity lesson) async {
    final result = await _repository.updateLesson(lesson);
    await result.fold<Future<void>>((failure) async {
      state = AsyncValue.error(failure.message, StackTrace.current);
      throw StateError(failure.message);
    }, (_) => loadLessons());
  }

  Future<void> deleteLesson(String id) async {
    final result = await _repository.deleteLesson(id);
    await result.fold<Future<void>>((failure) async {
      state = AsyncValue.error(failure.message, StackTrace.current);
      throw StateError(failure.message);
    }, (_) => loadLessons());
  }

  Future<void> seed() async {
    await loadLessons();
  }
}
