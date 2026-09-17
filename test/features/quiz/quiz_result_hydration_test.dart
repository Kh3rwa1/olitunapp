import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/core/languages/language_registry.dart';
import 'package:itun/core/languages/providers/target_language_provider.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/data/quiz_repository.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import 'package:itun/shared/providers/providers.dart';

/// The lesson catalog is intentionally metadata-only (blocks empty); the
/// full body arrives through [learnerLessonDetailProvider]. Quiz generation
/// must hydrate through that boundary — generating from the unhydrated
/// catalog is what produced the fake 1/1 lesson-title quiz for every
/// affected lesson.
LessonBlockEntity _block(int i, {bool withAudio = false}) {
  return LessonBlockEntity(
    type: 'sentence',
    textOlChiki: 'ᱥᱮᱸᱫᱨᱟ ᱠᱟᱛᱷᱟ $i',
    textLatin: 'Sendra katha number $i',
    audioUrl: withAudio ? 'https://example.com/audio/$i.mp3' : null,
    data: {
      'meaning_hi': 'हिंदी अर्थ संख्या $i',
      'meaning_en': 'English meaning number $i',
      'sourceSentenceId': 'sent_conv3_$i',
    },
  );
}

const _catalogLesson = LessonEntity(
  id: 'lesson_conv3',
  categoryId: 'cat_sentences',
  titleLatin: 'Modern Conversational Exchanges III',
  titleOlChiki: 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
);

LessonEntity _detailLesson({bool withAudio = false}) {
  return LessonEntity(
    id: 'lesson_conv3',
    categoryId: 'cat_sentences',
    titleLatin: 'Modern Conversational Exchanges III',
    titleOlChiki: 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
    blocks: List.generate(5, (i) => _block(i, withAudio: withAudio)),
  );
}

ProviderContainer _container({
  List<LessonEntity> catalog = const [_catalogLesson],
  AsyncValue<LessonEntity>? detail,
}) {
  return ProviderContainer(
    overrides: [
      learnerLessonsProvider.overrideWithValue(AsyncValue.data(catalog)),
      if (detail != null)
        learnerLessonDetailProvider('lesson_conv3').overrideWith((ref) {
          final snapshot = detail;
          return snapshot.when(
            data: Future.value,
            error: Future<LessonEntity>.error,
            loading: () => Completer<LessonEntity>().future,
          );
        }),
      effectiveTeachingLanguageProvider.overrideWithValue('hi'),
      effectiveScriptModeProvider.overrideWithValue('both'),
      activeLanguageManifestProvider.overrideWithValue(
        LanguageRegistry.findByCode('sat'),
      ),
    ],
  );
}

Either<Failure, QuizModel>? _data(ProviderContainer container, String quizId) {
  final async = container.read(quizResultProvider(quizId));
  return async.whenOrNull(data: (either) => either);
}

/// Lets the overridden lesson-detail future settle so [quizResultProvider]
/// observes data/error instead of the initial loading state.
Future<void> _settleDetail(ProviderContainer container) async {
  try {
    await container.read(learnerLessonDetailProvider('lesson_conv3').future);
  } catch (_) {
    // Errors are asserted through quizResultProvider below.
  }
  await container.pump();
}

/// Reads the quiz result after the lesson-detail future settles.
/// Subscribes to [quizResultProvider] first so the autoDispose detail
/// element stays alive until its future completes.
Future<Either<Failure, QuizModel>?> _resolvedData(
  ProviderContainer container,
  String quizId,
) async {
  container.read(quizResultProvider(quizId));
  await _settleDetail(container);
  await Future<void>.delayed(Duration.zero);
  return _data(container, quizId);
}

void main() {
  group('quizResultProvider lesson hydration', () {
    test('dynamic quiz hydrates the lesson body before generating', () async {
      final container = _container(detail: AsyncValue.data(_detailLesson()));
      addTearDown(container.dispose);

      final result = await _resolvedData(
        container,
        'dynamic_quiz_lesson_conv3',
      );

      expect(result, isNotNull);
      final quiz = result!.getOrElse((_) => throw StateError('expected quiz'));
      expect(quiz.questions, hasLength(5));
      for (final q in quiz.questions) {
        expect(q.promptLatin, 'Choose the correct Hindi meaning:');
        expect(q.promptLatin, isNot(contains('title for this lesson')));
      }
    });

    test('dynamic quiz stays loading while the body hydrates', () {
      final container = _container(detail: const AsyncValue.loading());
      addTearDown(container.dispose);

      expect(
        container.read(quizResultProvider('dynamic_quiz_lesson_conv3')),
        isA<AsyncLoading<Either<Failure, QuizModel>>>(),
      );
    });

    test('dynamic quiz fails closed when hydration fails', () async {
      final container = _container(
        detail: AsyncValue.error(StateError('offline'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      final result = await _resolvedData(
        container,
        'dynamic_quiz_lesson_conv3',
      );

      expect(result, isNotNull);
      expect(result!.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        'Could not load the lesson content.',
      );
    });

    test('dynamic quiz uses catalog blocks directly when present', () {
      final container = _container(catalog: [_detailLesson()]);
      addTearDown(container.dispose);

      final result = _data(container, 'dynamic_quiz_lesson_conv3');

      expect(result, isNotNull);
      final quiz = result!.getOrElse((_) => throw StateError('expected quiz'));
      expect(quiz.questions, hasLength(5));
    });

    test('unknown lesson stays not-found', () {
      final container = _container();
      addTearDown(container.dispose);

      final result = _data(container, 'dynamic_quiz_missing');

      expect(result, isNotNull);
      expect(result!.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'Lesson not found.');
    });

    test('listening quiz hydrates before checking for audio', () async {
      final container = _container(
        detail: AsyncValue.data(_detailLesson(withAudio: true)),
      );
      addTearDown(container.dispose);

      final result = await _resolvedData(
        container,
        'listening_quiz_lesson_conv3',
      );

      expect(result, isNotNull);
      final quiz = result!.getOrElse((_) => throw StateError('expected quiz'));
      expect(quiz.questions, hasLength(5));
      expect(quiz.questions.first.type, 'listen_meaning');
    });

    test('listening quiz without audio still reports unavailable', () async {
      final container = _container(detail: AsyncValue.data(_detailLesson()));
      addTearDown(container.dispose);

      final result = await _resolvedData(
        container,
        'listening_quiz_lesson_conv3',
      );

      expect(result, isNotNull);
      expect(result!.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        'No listening quiz available.',
      );
    });
  });
}
