import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../shared/models/catalog/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_providers.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/models/content_item_extensions.dart';
import '../../../../shared/providers/content_providers.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final lessonNotifierProvider =
    AsyncNotifierProvider<LessonNotifier, List<LessonEntity>>(
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

/// Admin/legacy lesson list. `build()` performs the fetch directly so
/// loading/error/data come from Riverpod; mutations write remotely and then
/// re-run `build()` via [loadLessons].
class LessonNotifier extends AsyncNotifier<List<LessonEntity>> {
  LessonRepository get _repository => ref.read(lessonRepositoryProvider);

  @override
  FutureOr<List<LessonEntity>> build() {
    ref.onDispose(() => _generation++);
    return _fetch();
  }

  Future<List<LessonEntity>> _fetch() async {
    final result = await _repository.getLessons();
    return result.fold(
      (failure) => throw FailureException(failure),
      _deduplicateLessons,
    );
  }

  /// Bumped whenever a build is disposed (rebuild or teardown) so a
  /// [loadLessons] response that resolves afterwards is dropped.
  int _generation = 0;

  /// Re-fetches the list. Previously loaded data stays visible while the
  /// request is in flight; a failure is surfaced through [state], not thrown.
  ///
  /// Writes `state` directly rather than `invalidateSelf()` + `await future`:
  /// callers (sync, prefetch, pull-to-refresh) may run while nothing listens
  /// to the provider, and then a pending dependency rebuild would never
  /// resolve `future`.
  Future<void> loadLessons() async {
    // As before: only show loading when there is nothing to keep on screen.
    if (!state.hasValue) state = const AsyncLoading<List<LessonEntity>>();
    final generation = _generation;
    final next = await AsyncValue.guard(_fetch);
    if (generation != _generation) return;
    state = next;
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
    await result.fold<Future<void>>(_failMutation, (_) => loadLessons());
  }

  Future<void> updateLesson(LessonEntity lesson) async {
    final result = await _repository.updateLesson(lesson);
    await result.fold<Future<void>>(_failMutation, (_) => loadLessons());
  }

  Future<void> deleteLesson(String id) async {
    final result = await _repository.deleteLesson(id);
    await result.fold<Future<void>>(_failMutation, (_) => loadLessons());
  }

  Future<void> _failMutation(Failure failure) async {
    state = AsyncValue.error(FailureException(failure), StackTrace.current);
    throw StateError(failure.message);
  }

  Future<void> seed() async {
    await loadLessons();
  }
}
