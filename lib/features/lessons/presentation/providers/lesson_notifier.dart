import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_providers.dart';

final lessonNotifierProvider =
    StateNotifierProvider<LessonNotifier, AsyncValue<List<LessonEntity>>>(
  (ref) => LessonNotifier(ref.watch(lessonRepositoryProvider)),
);

final lessonsByCategoryProvider =
    Provider.family<AsyncValue<List<LessonEntity>>, String>((ref, categoryId) {
  final lessonsAsync = ref.watch(lessonNotifierProvider);
  return lessonsAsync.when(
    data: (lessons) => AsyncValue.data(
      lessons.where((l) => l.categoryId == categoryId).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

class LessonNotifier extends StateNotifier<AsyncValue<List<LessonEntity>>> {
  final LessonRepository _repository;

  LessonNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLessons();
  }

  Future<void> loadLessons() async {
    state = const AsyncValue.loading();
    final result = await _repository.getLessons();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (lessons) => state = AsyncValue.data(lessons),
    );
  }

  Future<void> refresh() => loadLessons();

  Future<void> addLesson(LessonEntity lesson) async {
    final result = await _repository.createLesson(lesson);
    result.fold(
      (failure) => null,
      (_) => loadLessons(),
    );
  }

  Future<void> updateLesson(LessonEntity lesson) async {
    final result = await _repository.updateLesson(lesson);
    result.fold(
      (failure) => null,
      (_) => loadLessons(),
    );
  }

  Future<void> deleteLesson(String id) async {
    final result = await _repository.deleteLesson(id);
    result.fold(
      (failure) => null,
      (_) => loadLessons(),
    );
  }

  Future<void> seed() async {
    await loadLessons();
  }
}
