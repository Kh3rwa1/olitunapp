import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class _MockContentRepository extends Mock implements ContentRepository {}

List<ContentItem> _items(String title) => [
  ContentItem(
    id: 'cached_word',
    kind: ContentKind.word,
    categoryId: 'vocab',
    title: title,
    blocks: const [],
    updatedAt: DateTime(2026, 9, 8),
  ),
];

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late _MockContentRepository repository;
  late ProviderContainer container;
  late Completer<Either<Failure, List<ContentItem>>> refresh;
  late List<ContentItem> cached;
  var disposed = false;
  final provider = contentListProvider((ContentKind.word, 'vocab'));

  setUp(() async {
    repository = _MockContentRepository();
    refresh = Completer<Either<Failure, List<ContentItem>>>();
    cached = _items('Cached lesson');
    disposed = false;
    when(
      () => repository.cachedList(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer((_) async => Right(cached));
    when(
      () => repository.list(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer((_) => refresh.future);
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    await container.read(isAuthenticatedProvider.future);
  });

  tearDown(() {
    if (!disposed) container.dispose();
    if (!refresh.isCompleted) refresh.complete(const Right(<ContentItem>[]));
  });

  test('cached content appears before a blocked network refresh', () async {
    final initial = await container
        .read(provider.future)
        .timeout(const Duration(seconds: 1));
    expect(initial, same(cached));
    expect(refresh.isCompleted, isFalse);

    await _flushEvents();
    final fresh = _items('Fresh lesson');
    refresh.complete(Right(fresh));
    await _flushEvents();

    expect(container.read(provider).valueOrNull, same(fresh));
    expect(container.read(provider).hasError, isFalse);
    verify(
      () => repository.list(ContentKind.word, categoryId: 'vocab'),
    ).called(1);
  });

  test('fast refresh wins over the initial cache', () async {
    final fresh = _items('Fresh lesson');
    refresh.complete(Right(fresh));

    expect(await container.read(provider.future), same(cached));
    await _flushEvents();

    expect(container.read(provider).valueOrNull, same(fresh));
  });

  test('a failed refresh preserves usable local content', () async {
    expect(await container.read(provider.future), same(cached));
    await _flushEvents();
    refresh.complete(const Left(NetworkFailure()));
    await _flushEvents();

    expect(container.read(provider).valueOrNull, same(cached));
    expect(container.read(provider).hasError, isFalse);
  });

  test('refresh exceptions retain cached data', () async {
    expect(await container.read(provider.future), same(cached));
    await _flushEvents();
    refresh.completeError(StateError('transport failed'));
    await _flushEvents();

    expect(container.read(provider).valueOrNull, same(cached));
    expect(container.read(provider).hasError, isFalse);
  });

  test('no local content preserves the network failure contract', () async {
    when(
      () => repository.cachedList(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'No offline catalog.')),
    );
    const failure = NetworkFailure(message: 'Offline without a catalog');
    refresh.complete(const Left(failure));

    await expectLater(
      container.read(provider.future),
      throwsA(
        isA<FailureException>().having(
          (error) => error.failure,
          'failure',
          same(failure),
        ),
      ),
    );
    expect(container.read(provider).hasError, isTrue);
  });

  test('cache errors do not block the network', () async {
    when(
      () => repository.cachedList(ContentKind.word, categoryId: 'vocab'),
    ).thenThrow(StateError('cache unavailable'));
    final fresh = _items('Fresh lesson');
    refresh.complete(Right(fresh));

    expect(await container.read(provider.future), same(fresh));
  });

  test('invalidation ignores the old refresh', () async {
    expect(await container.read(provider.future), same(cached));
    await _flushEvents();
    final secondRefresh = Completer<Either<Failure, List<ContentItem>>>();
    final nextCached = _items('New local snapshot');
    when(
      () => repository.cachedList(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer((_) async => Right(nextCached));
    when(
      () => repository.list(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer((_) => secondRefresh.future);

    container.invalidate(provider);
    expect(await container.read(provider.future), same(nextCached));
    await _flushEvents();
    final latest = _items('Latest server snapshot');
    secondRefresh.complete(Right(latest));
    await _flushEvents();
    refresh.complete(Right(_items('Obsolete response')));
    await _flushEvents();

    expect(container.read(provider).valueOrNull, same(latest));
  });

  test('disposal cancels a refresh that has not started', () async {
    expect(await container.read(provider.future), same(cached));
    container.dispose();
    disposed = true;
    await _flushEvents();

    verifyNever(() => repository.list(ContentKind.word, categoryId: 'vocab'));
  });

  test('cold loading times out with a typed failure', () async {
    container.dispose();
    when(
      () => repository.cachedList(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'No offline catalog.')),
    );
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        isAuthenticatedProvider.overrideWith((ref) async => false),
        contentRequestTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    await container.read(isAuthenticatedProvider.future);

    await expectLater(
      container.read(provider.future),
      throwsA(
        isA<FailureException>().having(
          (error) => error.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ),
    );
    expect(container.read(provider).hasError, isTrue);
  });
}
