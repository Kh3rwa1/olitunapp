import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/lessons/data/di/lesson_di.dart';
import '../../features/lessons/domain/entities/lesson_entity.dart';
import '../../features/lessons/domain/entities/scoped_lesson_media.dart';
import '../models/content_item_extensions.dart';
import '../repositories/content_repository.dart';

final learnerCategoriesProvider = FutureProvider<List<CategoryEntity>>((
  ref,
) async {
  final items = await ref.watch(
    contentListProvider(const ContentQuery(kind: ContentKind.category)).future,
  );
  return items.map((item) => item.toCategoryEntity()).toList(growable: false);
});

final learnerLessonsProvider = FutureProvider<List<LessonEntity>>((ref) async {
  final items = await ref.watch(
    contentListProvider(const ContentQuery(kind: ContentKind.lesson)).future,
  );
  return items
      .map((item) => scopeLessonMedia(item.toLessonEntity()))
      .toList(growable: false);
});

/// Loads the selected lesson body through the authorized detail boundary.
/// Catalog providers intentionally keep lesson blocks empty.
final learnerLessonDetailProvider =
    FutureProvider.autoDispose.family<LessonEntity, String>((
      ref,
      lessonId,
    ) async {
      await ref.watch(currentUserProvider.future);
      final result = await ref
          .watch(lessonRepositoryProvider)
          .getLessonById(lessonId);
      return result.fold(
        (failure) => throw StateError(failure.message),
        (lesson) {
          if (lesson.id != lessonId) {
            throw StateError(
              'Authorized lesson response did not match request',
            );
          }
          return scopeLessonMedia(lesson);
        },
      );
    });

final learnerCategoriesForLanguageProvider =
    FutureProvider.family<List<CategoryEntity>, String>((ref, language) async {
      final normalized = language.trim();
      final items = await ref.watch(
        contentListProvider(
          ContentQuery(
            kind: ContentKind.category,
            language: normalized.isEmpty ? null : normalized,
          ),
        ).future,
      );
      return items
          .map((item) => item.toCategoryEntity())
          .toList(growable: false);
    });

final learnerLessonsForLanguageProvider =
    FutureProvider.family<List<LessonEntity>, String>((ref, language) async {
      final normalized = language.trim();
      final items = await ref.watch(
        contentListProvider(
          ContentQuery(
            kind: ContentKind.lesson,
            language: normalized.isEmpty ? null : normalized,
          ),
        ).future,
      );
      return items
          .map((item) => scopeLessonMedia(item.toLessonEntity()))
          .toList(growable: false);
    });
