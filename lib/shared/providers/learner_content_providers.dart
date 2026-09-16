import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/lessons/data/di/lesson_di.dart';
import '../../features/lessons/domain/entities/lesson_entity.dart';
import '../../features/lessons/domain/entities/scoped_lesson_media.dart';
import '../models/content_models.dart';
import '../repositories/content_repository.dart';

final learnerLessonsProvider = Provider<AsyncValue<List<LessonEntity>>>((ref) {
  return ref
      .watch(contentListProvider((ContentKind.lesson, null)))
      .whenData(
        (list) => list
            .map((item) => scopeLessonMedia(item.toLessonEntity()))
            .toList(),
      );
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

final learnerWordsProvider = Provider<AsyncValue<List<WordModel>>>((ref) {
  return ref
      .watch(contentListProvider((ContentKind.word, null)))
      .whenData((list) => list.map((item) => item.toWordModel()).toList());
});

final learnerLettersProvider = Provider<AsyncValue<List<LetterModel>>>((ref) {
  return ref
      .watch(contentListProvider((ContentKind.letter, null)))
      .whenData((list) => list.map((item) => item.toLetterModel()).toList());
});

final learnerNumbersProvider = Provider<AsyncValue<List<NumberModel>>>((ref) {
  return ref
      .watch(contentListProvider((ContentKind.number, null)))
      .whenData((list) => list.map((item) => item.toNumberModel()).toList());
});

final learnerSentencesProvider = Provider<AsyncValue<List<SentenceModel>>>((
  ref,
) {
  return ref
      .watch(contentListProvider((ContentKind.sentence, null)))
      .whenData((list) => list.map((item) => item.toSentenceModel()).toList());
});
