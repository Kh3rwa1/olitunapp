import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/content/content_state.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/features/lessons/data/repositories/lesson_repository_impl.dart';

class _MockRemote extends Mock implements LessonRemoteDataSource {}

class _MockLocal extends Mock implements LessonLocalDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

LessonModel _model(String id, {String cat = 'cat_alphabets'}) => LessonModel(
  id: id,
  categoryId: cat,
  titleOlChiki: 'ᱚ',
  titleLatin: 'Lesson $id',
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

  group('ContentState Typed Lifecycles', () {
    test('Initializes with correct source and freshness flags', () {
      final initial = ContentState<String>.noData();
      expect(initial.hasData, isFalse);
      expect(initial.isAvailable, isFalse);
      expect(initial.source, ContentSource.none);
      expect(initial.freshness, ContentFreshness.initial);

      final cached = ContentState<String>.freshCache('data');
      expect(cached.hasData, isTrue);
      expect(cached.isFromCache, isTrue);
      expect(cached.freshness, ContentFreshness.fresh);

      final stale = ContentState<String>.staleCache('data', isRefreshing: true);
      expect(stale.isStale, isTrue);
      expect(stale.isRefreshing, isTrue);

      final seed = ContentState<String>.offlineUsingSeed('seed');
      expect(seed.isFromSeed, isTrue);
      expect(seed.hasData, isTrue);

      final failed = ContentState<String>.refreshFailedUsingCache(
        'data',
        const ServerFailure(message: 'timeout'),
      );
      expect(failed.hasData, isTrue);
      expect(failed.failure, isNotNull);
      expect(failed.freshness, ContentFreshness.failed);
    });
  });

  group('LessonRepositoryImpl SWR & In-Flight Deduplication', () {
    test(
      'Returns cached data immediately while revalidating in background',
      () async {
        when(
          () => local.getLessons(),
        ).thenAnswer((_) async => [_model('cached_1')]);
        when(() => network.isConnected).thenAnswer((_) async => true);

        final remoteCompleter = Completer<List<LessonModel>>();
        when(
          () => remote.getLessons(),
        ).thenAnswer((_) => remoteCompleter.future);
        when(() => local.cacheLessons(any())).thenAnswer((_) async {});

        final result = await repo.getLessons();

        expect(result.isRight(), isTrue);
        expect(result.getOrElse((_) => []).first.id, 'cached_1');

        // Finish background revalidation
        remoteCompleter.complete([_model('remote_1')]);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verify(() => remote.getLessons()).called(1);
        verify(() => local.cacheLessons(any())).called(1);
      },
    );

    test(
      'Deduplicates multiple simultaneous calls into a single remote fetch',
      () async {
        when(() => local.getLessons()).thenAnswer((_) async => []);
        when(() => network.isConnected).thenAnswer((_) async => true);

        int remoteCallCount = 0;
        when(() => remote.getLessons()).thenAnswer((_) async {
          remoteCallCount++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return [_model('lesson_dedup')];
        });
        when(() => local.cacheLessons(any())).thenAnswer((_) async {});

        final results = await Future.wait([
          repo.getLessons(),
          repo.getLessons(),
          repo.getLessons(),
        ]);

        expect(
          remoteCallCount,
          1,
          reason:
              'Only 1 remote fetch should be executed across 3 concurrent calls',
        );
        expect(results.length, 3);
        for (final r in results) {
          expect(r.isRight(), isTrue);
          expect(r.getOrElse((_) => []).first.id, 'lesson_dedup');
        }
      },
    );

    test('Discards invalid models before writing to cache', () async {
      when(() => local.getLessons()).thenAnswer((_) async => []);
      when(() => network.isConnected).thenAnswer((_) async => true);

      const invalidModel = LessonModel(
        id: '', // Invalid empty ID
        categoryId: '',
        titleOlChiki: '',
        titleLatin: '',
        blocks: [],
      );
      final validModel = _model('valid_1');

      when(
        () => remote.getLessons(),
      ).thenAnswer((_) async => [invalidModel, validModel]);
      when(() => local.cacheLessons(any())).thenAnswer((_) async {});

      final result = await repo.getLessons();

      expect(result.isRight(), isTrue);
      final lessons = result.getOrElse((_) => []);
      expect(lessons.length, 1);
      expect(lessons.first.id, 'valid_1');

      verify(() => local.cacheLessons([validModel])).called(1);
    });
  });
}
