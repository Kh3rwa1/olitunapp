import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_providers.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/models/content_item_extensions.dart';
import '../../../../shared/providers/content_providers.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final lessonNotifierProvider =
    NotifierProvider<LessonNotifier, AsyncValue<List<LessonEntity>>>(
      LessonNotifier.new,
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

class LessonNotifier extends Notifier<AsyncValue<List<LessonEntity>>> {
  bool _disposed = false;

  LessonRepository get _repository => ref.read(lessonRepositoryProvider);

  @override
  AsyncValue<List<LessonEntity>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadLessons);
    return const AsyncValue.loading();
  }

  Future<void> loadLessons() async {
    if (_disposed) return;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    final result = await _repository.getLessons();
    if (_disposed) return;
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
