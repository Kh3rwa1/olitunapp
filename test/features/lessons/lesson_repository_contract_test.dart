import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';

class _MockLessonRepository extends Mock implements LessonRepository {}

/// Hand-written fake proving the interface contract without mocks:
/// every method returns the fixture data it was built with.
class _RecordingLessonRepository implements LessonRepository {
  _RecordingLessonRepository(this.lessons);

  final List<LessonEntity> lessons;
  final List<String> deletedIds = [];
  final List<LessonEntity> savedLessons = [];
  String? lastQueriedCategory;

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessons() async =>
      Right(lessons);

  @override
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(
    String categoryId,
  ) async {
    lastQueriedCategory = categoryId;
    return Right(lessons.where((l) => l.categoryId == categoryId).toList());
  }

  @override
  Future<Either<Failure, LessonEntity>> getLessonById(String id) async {
    for (final lesson in lessons) {
      if (lesson.id == id) return Right(lesson);
    }
    return const Left(CacheFailure(message: 'lesson not found'));
  }

  @override
  Future<Either<Failure, void>> createLesson(LessonEntity lesson) async {
    savedLessons.add(lesson);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateLesson(LessonEntity lesson) async {
    savedLessons.add(lesson);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteLesson(String id) async {
    deletedIds.add(id);
    return const Right(null);
  }
}

const _alphabetLesson = LessonEntity(
  id: 'l1',
  categoryId: 'alphabets',
  titleOlChiki: 'ᱚᱠᱷᱚᱨ',
  titleLatin: 'Vowels',
);

const _numberLesson = LessonEntity(
  id: 'l2',
  categoryId: 'numbers',
  titleOlChiki: 'ᱮᱞ',
  titleLatin: 'Numbers 1–10',
  order: 1,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_alphabetLesson);
  });

  group('LessonRepository contract', () {
    test('getLessons returns the full catalog on success', () async {
      final repo = _RecordingLessonRepository([_alphabetLesson, _numberLesson]);

      final result = await repo.getLessons();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), hasLength(2));
    });

    test('getLessonsByCategory filters by categoryId', () async {
      final repo = _RecordingLessonRepository([_alphabetLesson, _numberLesson]);

      final result = await repo.getLessonsByCategory('numbers');

      expect(repo.lastQueriedCategory, 'numbers');
      expect(result.getRight().toNullable()?.single.id, _numberLesson.id);
    });

    test('getLessonById returns the lesson or a NotFoundFailure', () async {
      final repo = _RecordingLessonRepository([_alphabetLesson]);

      final found = await repo.getLessonById('l1');
      final missing = await repo.getLessonById('nope');

      expect(found.isRight(), isTrue);
      expect(found.getRight().toNullable()?.titleLatin, 'Vowels');
      expect(missing.isLeft(), isTrue);
      expect(missing.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('create, update and delete all resolve to Right(null)', () async {
      final repo = _RecordingLessonRepository([]);

      expect((await repo.createLesson(_numberLesson)).isRight(), isTrue);
      expect((await repo.updateLesson(_alphabetLesson)).isRight(), isTrue);
      expect((await repo.deleteLesson('l1')).isRight(), isTrue);

      expect(repo.savedLessons, hasLength(2));
      expect(repo.deletedIds, ['l1']);
    });

    test(
      'mock-typed repositories satisfy the interface and surface failures',
      () async {
        final repo = _MockLessonRepository();
        when(repo.getLessons).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'offline')),
        );
        when(
          () => repo.getLessonById(any()),
        ).thenAnswer((_) async => const Right(_alphabetLesson));

        final failure = await repo.getLessons();
        final success = await repo.getLessonById('l1');

        expect(failure.getLeft().toNullable(), isA<NetworkFailure>());
        expect(success.getRight().toNullable()!.id, 'l1');
        verify(repo.getLessons).called(1);
      },
    );
  });
}
