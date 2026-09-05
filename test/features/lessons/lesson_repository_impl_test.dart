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
    registerFallbackValue(_lesson('fallback'));
    registerFallbackValue(Duration.zero);

    when(
      () => local.cacheAuthorizedLesson(
        userId: any(named: 'userId'),
        lesson: any(named: 'lesson'),
        gracePeriod: any(named: 'gracePeriod'),
        isExplicitlyDenied: any(named: 'isExplicitlyDenied'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.invalidateAuthorizedLesson(
        userId: any(named: 'userId'),
        lessonId: any(named: 'lessonId'),
        markExplicitlyDenied: any(named: 'markExplicitlyDenied'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.getAuthorizedLesson(
        userId: any(named: 'userId'),
        lessonId: any(named: 'lessonId'),
      ),
    ).thenAnswer((_) async => null);
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
    test(
      'returns remote lesson and caches it when online and unlocked',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getAuthorizedLesson('1'),
        ).thenAnswer((_) async => _lesson('1'));

        final result = await repo.getLessonById('1');

        expect(result.isRight(), isTrue);
        result.match(
          (_) => fail('should be right'),
          (lesson) => expect(lesson.id, '1'),
        );
        verify(
          () => local.cacheAuthorizedLesson(
            userId: 'guest',
            lesson: any(named: 'lesson'),
            gracePeriod: any(named: 'gracePeriod'),
          ),
        ).called(1);
      },
    );

    test(
      'returns locked lesson without caching and marks explicit denial when backend returns locked',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        const lockedLesson = LessonModel(
          id: 'locked_1',
          categoryId: 'cat',
          titleOlChiki: 'ᱚ',
          titleLatin: 'a',
          isLocked: true,
          blocks: [],
        );
        when(
          () => remote.getAuthorizedLesson('locked_1'),
        ).thenAnswer((_) async => lockedLesson);

        final result = await repo.getLessonById('locked_1');

        expect(result.isRight(), isTrue);
        result.match((_) => fail('should be right'), (lesson) {
          expect(lesson.id, 'locked_1');
          expect(lesson.isLocked, isTrue);
          expect(lesson.blocks, isEmpty);
        });
        verifyNever(
          () => local.cacheAuthorizedLesson(
            userId: any(named: 'userId'),
            lesson: any(named: 'lesson'),
            gracePeriod: any(named: 'gracePeriod'),
          ),
        );
        verify(
          () => local.invalidateAuthorizedLesson(
            userId: 'guest',
            lessonId: 'locked_1',
          ),
        ).called(1);
      },
    );

    test('returns AuthFailure and invalidates cache on remote 403', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getAuthorizedLesson('1')).thenThrow(
        ServerException(message: 'Access denied to lesson', code: 403),
      );

      final result = await repo.getLessonById('1');

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('should be Left(AuthFailure)'),
      );
      verify(
        () => local.invalidateAuthorizedLesson(userId: 'guest', lessonId: '1'),
      ).called(1);
    });

    test(
      'falls back to local cache when online remote call fails with server error',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getAuthorizedLesson('1'),
        ).thenThrow(ServerException(message: 'boom', code: 500));
        when(
          () => local.getAuthorizedLesson(userId: 'guest', lessonId: '1'),
        ).thenAnswer(
          (_) async => AuthorizedLessonCacheEntry(
            lesson: const LessonModel(
              id: '1',
              categoryId: 'cat',
              titleOlChiki: 'ᱚ',
              titleLatin: 'a',
              blocks: [
                LessonBlockModel(type: 'text', textLatin: 'cached content'),
              ],
            ),
            userId: 'guest',
            cachedAtMs: DateTime.now().millisecondsSinceEpoch,
            expiresAtMs:
                DateTime.now().millisecondsSinceEpoch +
                const Duration(hours: 24).inMilliseconds,
          ),
        );

        final result = await repo.getLessonById('1');

        result.match(
          (_) => fail('should be right'),
          (lesson) => expect(lesson.id, '1'),
        );
      },
    );

    test(
      'falls back to static seed lesson when remote and cache fail online',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getAuthorizedLesson('lesson_alphabet_0'),
        ).thenThrow(ServerException(message: 'boom', code: 500));
        when(
          () => local.getAuthorizedLesson(
            userId: 'guest',
            lessonId: 'lesson_alphabet_0',
          ),
        ).thenAnswer((_) async => null);

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
        () => remote.getAuthorizedLesson('1'),
      ).thenAnswer((_) async => _lesson('fresh_1'));
      when(
        () => local.cacheAuthorizedLesson(
          userId: any(named: 'userId'),
          lesson: any(named: 'lesson'),
          gracePeriod: any(named: 'gracePeriod'),
          isExplicitlyDenied: any(named: 'isExplicitlyDenied'),
        ),
      ).thenThrow(CacheException(message: 'disk full'));

      final result = await repo.getLessonById('1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('should be right'),
        (lesson) => expect(lesson.id, 'fresh_1'),
      );
    });

    test(
      'offline access allowed within 24-hour offline grace period',
      () async {
        final now = DateTime(2026, 1, 1, 12);
        final scopedRepo = LessonRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
          networkInfo: network,
          currentUserIdProvider: () async => 'user_premium_123',
          clock: () => now,
        );

        when(() => network.isConnected).thenAnswer((_) async => false);
        when(
          () => local.getAuthorizedLesson(
            userId: 'user_premium_123',
            lessonId: 'paid_1',
          ),
        ).thenAnswer(
          (_) async => AuthorizedLessonCacheEntry(
            lesson: _lesson('paid_1'),
            userId: 'user_premium_123',
            cachedAtMs: now
                .subtract(const Duration(hours: 12))
                .millisecondsSinceEpoch,
            expiresAtMs: now
                .add(const Duration(hours: 12))
                .millisecondsSinceEpoch,
          ),
        );

        final result = await scopedRepo.getLessonById('paid_1');

        expect(result.isRight(), isTrue);
        result.match(
          (_) => fail('should be right'),
          (lesson) => expect(lesson.id, 'paid_1'),
        );
      },
    );

    test(
      'offline access rejected when 24-hour offline grace period expired',
      () async {
        final baseTime = DateTime(2026, 1, 1, 12);
        final expiredTime = baseTime.add(const Duration(hours: 25));
        final scopedRepo = LessonRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
          networkInfo: network,
          currentUserIdProvider: () async => 'user_premium_123',
          clock: () => expiredTime,
        );

        when(() => network.isConnected).thenAnswer((_) async => false);
        when(
          () => local.getAuthorizedLesson(
            userId: 'user_premium_123',
            lessonId: 'paid_1',
          ),
        ).thenAnswer(
          (_) async => AuthorizedLessonCacheEntry(
            lesson: _lesson('paid_1'),
            userId: 'user_premium_123',
            cachedAtMs: baseTime.millisecondsSinceEpoch,
            expiresAtMs: baseTime
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch,
          ),
        );

        final result = await scopedRepo.getLessonById('paid_1');

        expect(result.isLeft(), isTrue);
        result.match((f) {
          expect(f, isA<AuthFailure>());
          expect(f.message, contains('grace period expired'));
        }, (_) => fail('should be Left(AuthFailure)'));
      },
    );

    test(
      'user isolation prevents User B from accessing User A cached lesson offline',
      () async {
        final scopedRepo = LessonRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
          networkInfo: network,
          currentUserIdProvider: () async => 'user_B',
        );

        when(() => network.isConnected).thenAnswer((_) async => false);
        // User B's cache is empty
        when(
          () => local.getAuthorizedLesson(userId: 'user_B', lessonId: 'paid_1'),
        ).thenAnswer((_) async => null);

        final result = await scopedRepo.getLessonById('paid_1');

        expect(result.isLeft(), isTrue);
        result.match(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('should be Left(CacheFailure)'),
        );
      },
    );

    test(
      'explicit denial marker blocks offline replay after revocation',
      () async {
        final scopedRepo = LessonRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
          networkInfo: network,
          currentUserIdProvider: () async => 'user_refunded',
        );

        when(() => network.isConnected).thenAnswer((_) async => false);
        when(
          () => local.getAuthorizedLesson(
            userId: 'user_refunded',
            lessonId: 'paid_1',
          ),
        ).thenAnswer(
          (_) async => AuthorizedLessonCacheEntry(
            lesson: _lesson('paid_1'),
            userId: 'user_refunded',
            cachedAtMs: DateTime.now().millisecondsSinceEpoch,
            expiresAtMs:
                DateTime.now().millisecondsSinceEpoch +
                const Duration(days: 30).inMilliseconds,
            isExplicitlyDenied: true,
          ),
        );

        final result = await scopedRepo.getLessonById('paid_1');

        expect(result.isLeft(), isTrue);
        result.match(
          (f) => expect(f, isA<AuthFailure>()),
          (_) => fail('should be Left(AuthFailure)'),
        );
      },
    );

    test(
      'offline request for unknown protected lesson returns CacheFailure without fabricating seed',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        when(
          () => local.getAuthorizedLesson(
            userId: 'guest',
            lessonId: 'non_seed_premium_99',
          ),
        ).thenAnswer((_) async => null);

        final result = await repo.getLessonById('non_seed_premium_99');

        expect(result.isLeft(), isTrue);
        result.match(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('should be Left(CacheFailure)'),
        );
      },
    );
  });
}
