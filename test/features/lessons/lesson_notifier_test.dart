import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';

class _MockLessonRepository extends Mock implements LessonRepository {}

void main() {
  late _MockLessonRepository mockRepo;

  setUp(() {
    mockRepo = _MockLessonRepository();
  });

  setUpAll(() {
    registerFallbackValue(const LessonEntity(
      id: 'fallback',
      categoryId: 'cat',
      titleOlChiki: '',
      titleLatin: '',
    ));
  });

  final sampleLessons = [
    const LessonEntity(
      id: 'l1',
      categoryId: 'alphabets',
      titleOlChiki: 'ᱚᱠᱷᱚᱨ',
      titleLatin: 'Vowels',
      order: 0,
    ),
    const LessonEntity(
      id: 'l2',
      categoryId: 'numbers',
      titleOlChiki: 'ᱮᱞ',
      titleLatin: 'Numbers 1–10',
      order: 1,
    ),
  ];

  group('LessonNotifier', () {
    test('starts in loading then emits data on success', () async {
      when(() => mockRepo.getLessons())
          .thenAnswer((_) async => Right(sampleLessons));

      final notifier = LessonNotifier(mockRepo);

      // Give the async init time to complete.
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(notifier.state.value, isNotNull);
      expect(notifier.state.value!.length, 2);
      expect(notifier.state.value!.first.id, 'l1');
    });

    test('emits error on repository failure', () async {
      when(() => mockRepo.getLessons()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'timeout', code: 500)),
      );

      final notifier = LessonNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(notifier.state.hasError, isTrue);
    });

    test('refresh re-fetches lessons', () async {
      when(() => mockRepo.getLessons())
          .thenAnswer((_) async => Right(sampleLessons));

      final notifier = LessonNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.refresh();
      verify(() => mockRepo.getLessons()).called(2);
    });

    test('addLesson calls repository and refreshes', () async {
      when(() => mockRepo.getLessons())
          .thenAnswer((_) async => Right(sampleLessons));
      when(() => mockRepo.createLesson(any()))
          .thenAnswer((_) async => const Right(null));

      final notifier = LessonNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.addLesson(sampleLessons.first);

      verify(() => mockRepo.createLesson(any())).called(1);
      // Once on init + once after add.
      verify(() => mockRepo.getLessons()).called(greaterThanOrEqualTo(2));
    });

    test('deleteLesson calls repository and refreshes', () async {
      when(() => mockRepo.getLessons())
          .thenAnswer((_) async => Right(sampleLessons));
      when(() => mockRepo.deleteLesson(any()))
          .thenAnswer((_) async => const Right(null));

      final notifier = LessonNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.deleteLesson('l1');
      verify(() => mockRepo.deleteLesson('l1')).called(1);
    });

    test('addLesson swallows failure silently', () async {
      when(() => mockRepo.getLessons())
          .thenAnswer((_) async => Right(sampleLessons));
      when(() => mockRepo.createLesson(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'conflict')),
      );

      final notifier = LessonNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Should not throw.
      await notifier.addLesson(sampleLessons.first);
      expect(notifier.state.hasValue, isTrue);
    });
  });

  group('lessonsByCategoryProvider', () {
    test('filters lessons by categoryId', () {
      final container = ProviderContainer(
        overrides: [
          lessonNotifierProvider.overrideWith(
            (ref) {
              final n = LessonNotifier(mockRepo);
              // Manually set state to avoid async init.
              n.state = AsyncValue.data(sampleLessons);
              return n;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      final filtered = container.read(lessonsByCategoryProvider('alphabets'));
      expect(filtered.value?.length, 1);
      expect(filtered.value?.first.id, 'l1');

      final nums = container.read(lessonsByCategoryProvider('numbers'));
      expect(nums.value?.length, 1);
      expect(nums.value?.first.id, 'l2');

      final empty = container.read(lessonsByCategoryProvider('nonexistent'));
      expect(empty.value?.length, 0);
    });
  });
}
