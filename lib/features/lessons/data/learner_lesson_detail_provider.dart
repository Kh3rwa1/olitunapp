import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/languages/providers/target_language_provider.dart';
import '../../../shared/models/catalog/lesson_entity.dart';
import '../../../shared/models/catalog/scoped_lesson_media.dart';
import '../../../shared/providers/language_settings_providers.dart';
import 'di/lesson_di.dart';

/// Loads the selected lesson body through the authorized detail boundary.
/// Catalog providers intentionally keep lesson blocks empty.
final learnerLessonDetailProvider = FutureProvider.autoDispose
    .family<LessonEntity, String>((ref, lessonId) async {
      await ref.watch(currentUserProvider.future);
      ref.watch(targetLanguageCodeProvider);
      ref.watch(effectiveTeachingLanguageProvider);
      final result = await ref
          .watch(lessonRepositoryProvider)
          .getLessonById(lessonId);
      return result.fold((failure) => throw StateError(failure.message), (
        lesson,
      ) {
        if (lesson.id != lessonId) {
          throw StateError('Authorized lesson response did not match request');
        }
        return scopeLessonMedia(lesson);
      });
    });
