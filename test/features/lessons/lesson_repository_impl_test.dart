import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/features/lessons/data/repositories/lesson_repository_impl.dart';

class _MockRemote extends Mock implements LessonRemoteDataSource {}

class _MockLocal extends Mock implements LessonLocalDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

LessonModel _lesson(String id, {String categoryId = 'cat'}) => LessonModel(
  id: id,
  categoryId: categoryId,
  titleOlChiki: 'ᱚ',
  titleLatin: 'a',
  blocks: const [],
);

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetwork network;
  late LessonRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    network = _MockNetwork();
    repo = LessonRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
    );
    registerFallbackValue(<LessonModel>[]);
  });

  group('getLessons', () {
    test('returns remote lessons and caches them when online', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getLessons()).thenAnswer((_) async => [_lesson('1')]);
      when(() => local.cacheLessons(any())).thenAnswer((_) async {});

      final result = await repo.getLessons();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('should be right'),
        (lessons) => expect(lessons.single.id, '1'),
      );
      verify(() => local.cacheLessons(any())).called(1);
    });

    test('falls back to cache on remote ServerException', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLessons(),
      ).thenThrow(ServerException(message: 'boom', code: 500));
      when(() => local.getLessons()).thenAnswer((_) async => [_lesson('c')]);

      final result = await repo.getLessons();

      result.match(
        (_) => fail('should be right (cache hit)'),
        (lessons) => expect(lessons.single.id, 'c'),
      );
    });

    test('returns static seed lessons when offline AND cache empty', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(
        () => local.getLessons(),
      ).thenThrow(CacheException(message: 'no cache'));

      final result = await repo.getLessons();

      result.match((_) => fail('should be right'), (lessons) {
        expect(lessons, isNotEmpty);
        expect(lessons.first.id, 'lesson_alphabet_0');
      });
    });

    test('uses cache when offline AND cache populated', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.getLessons()).thenAnswer((_) async => [_lesson('x')]);

      final result = await repo.getLessons();

      result.match(
        (_) => fail('should be right'),
        (lessons) => expect(lessons.single.id, 'x'),
      );
    });
    test('returns remote lessons even if cache writing fails', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLessons(),
      ).thenAnswer((_) async => [_lesson('fresh')]);
      when(
        () => local.cacheLessons(any()),
      ).thenThrow(CacheException(message: 'disk full'));

      final result = await repo.getLessons();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('should be right'),
        (lessons) => expect(lessons.single.id, 'fresh'),
      );
    });
  });

  group('getLessonsByCategory', () {
    test(
      'returns remote category lessons even if cache writing fails',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLessonsByCategory(any()),
        ).thenAnswer((_) async => [_lesson('fresh_cat')]);
        when(
          () => local.cacheLessons(any()),
        ).thenThrow(CacheException(message: 'disk full'));

        final result = await repo.getLessonsByCategory('cat');

        expect(result.isRight(), isTrue);
        result.match(
          (_) => fail('should be right'),
          (lessons) => expect(lessons.single.id, 'fresh_cat'),
        );
      },
    );

    test(
      'returns NetworkFailure when offline AND local cache throws',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        when(() => local.getLessons()).thenThrow(Exception('disk'));

        final result = await repo.getLessonsByCategory('cat');

        result.match(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('should be left'),
        );
      },
    );

    test(
      'falls back to matching cached category when remote throws online',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLessonsByCategory(any()),
        ).thenThrow(ServerException(message: 'nope', code: 500));
        when(() => local.getLessons()).thenAnswer(
          (_) async => [
            _lesson('matched'),
            _lesson('other', categoryId: 'other'),
          ],
        );

        final result = await repo.getLessonsByCategory('cat');

        result.match((_) => fail('should be right'), (lessons) {
          expect(lessons, hasLength(1));
          expect(lessons.single.id, 'matched');
        });
      },
    );

    test(
      'returns static seed lessons by category when remote and cache both fail online',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLessonsByCategory(any()),
        ).thenThrow(ServerException(message: 'nope', code: 500));
        when(
          () => local.getLessons(),
        ).thenThrow(CacheException(message: 'no cache'));

        final result = await repo.getLessonsByCategory('cat_alphabets');

        result.match((_) => fail('should be right'), (lessons) {
          expect(lessons, isNotEmpty);
          expect(lessons.first.id, 'lesson_alphabet_0');
        });
      },
    );
  });

  group('getLessonById', () {
    test('returns remote lesson and caches it when online', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLessonById('1'),
      ).thenAnswer((_) async => _lesson('1'));
      when(() => local.cacheLessons(any())).thenAnswer((_) async {});

      final result = await repo.getLessonById('1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('should be right'),
        (lesson) => expect(lesson.id, '1'),
      );
    });

    test('falls back to local cache when online remote call fails', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLessonById('1'),
      ).thenThrow(ServerException(message: 'boom', code: 500));
      when(() => local.getLessons()).thenAnswer((_) async => [_lesson('1')]);

      final result = await repo.getLessonById('1');

      result.match(
        (_) => fail('should be right'),
        (lesson) => expect(lesson.id, '1'),
      );
    });

    test(
      'falls back to static seed lesson when remote and cache fail online',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLessonById('lesson_alphabet_0'),
        ).thenThrow(ServerException(message: 'boom', code: 500));
        when(
          () => local.getLessons(),
        ).thenThrow(CacheException(message: 'no cache'));

        final result = await repo.getLessonById('lesson_alphabet_0');

        result.match(
          (_) => fail('should be right'),
          (lesson) => expect(lesson.id, 'lesson_alphabet_0'),
        );
      },
    );
    test('returns remote lesson by id even if cache writing fails', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLessonById('1'),
      ).thenAnswer((_) async => _lesson('fresh_1'));
      when(
        () => local.cacheLessons(any()),
      ).thenThrow(CacheException(message: 'disk full'));

      final result = await repo.getLessonById('1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('should be right'),
        (lesson) => expect(lesson.id, 'fresh_1'),
      );
    });
  });
}
