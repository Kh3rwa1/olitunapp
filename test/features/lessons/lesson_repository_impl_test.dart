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

LessonModel _lesson(String id) => LessonModel(
      id: id,
      categoryId: 'cat',
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
      result.match((_) => fail('should be right'),
          (lessons) => expect(lessons.single.id, '1'));
      verify(() => local.cacheLessons(any())).called(1);
    });

    test('falls back to cache on remote ServerException', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getLessons())
          .thenThrow(ServerException(message: 'boom', code: 500));
      when(() => local.getLessons()).thenAnswer((_) async => [_lesson('c')]);

      final result = await repo.getLessons();

      result.match((_) => fail('should be right (cache hit)'),
          (lessons) => expect(lessons.single.id, 'c'));
    });

    test('returns ServerFailure when offline AND cache empty', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.getLessons())
          .thenThrow(CacheException(message: 'no cache'));

      final result = await repo.getLessons();

      result.match(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'No internet connection');
        },
        (_) => fail('should be left'),
      );
    });

    test('uses cache when offline AND cache populated', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.getLessons()).thenAnswer((_) async => [_lesson('x')]);

      final result = await repo.getLessons();

      result.match((_) => fail('should be right'),
          (lessons) => expect(lessons.single.id, 'x'));
    });
  });

  group('getLessonsByCategory', () {
    test('returns NetworkFailure when offline AND local cache throws',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      when(() => local.getLessons()).thenThrow(Exception('disk'));

      final result = await repo.getLessonsByCategory('cat');

      result.match(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('should be left'),
      );
    });

    test('returns ServerFailure when remote throws while online', () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getLessonsByCategory(any()))
          .thenThrow(ServerException(message: 'nope', code: 500));

      final result = await repo.getLessonsByCategory('cat');

      result.match(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'nope');
        },
        (_) => fail('should be left'),
      );
    });
  });
}
