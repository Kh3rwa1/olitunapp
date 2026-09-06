import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class _ContentRepo extends Mock implements ContentRepository {}

void main() {
  late _ContentRepo repo;
  late ProviderContainer container;
  final provider = contentListProvider((ContentKind.word, 'cat_vocab'));
  final item = ContentItem.empty(id: 'word_one', kind: ContentKind.word);

  Future<Either<Failure, List<ContentItem>>> list() {
    return repo.list(ContentKind.word, categoryId: 'cat_vocab');
  }

  setUp(() async {
    repo = _ContentRepo();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repo),
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    addTearDown(container.dispose);
    await container.read(isAuthenticatedProvider.future);
  });

  test('preserves successful content', () async {
    when(list).thenAnswer((_) async => Right([item]));

    expect(await container.read(provider.future), [item]);
    verify(list).called(1);
  });

  test('a genuinely empty result remains successful', () async {
    when(list).thenAnswer((_) async => const Right(<ContentItem>[]));

    expect(await container.read(provider.future), isEmpty);
    expect(container.read(provider).hasError, isFalse);
  });

  for (final failure in const <Failure>[
    CacheFailure(message: 'No offline content'),
    NetworkFailure(message: 'Offline'),
    ServerFailure(message: 'Unavailable'),
  ]) {
    test('preserves typed failure: ${failure.runtimeType}', () async {
      when(list).thenAnswer((_) async => Left(failure));
      final matcher = isA<FailureException>().having(
        (error) => error.failure,
        'failure',
        same(failure),
      );

      await expectLater(container.read(provider.future), throwsA(matcher));

      expect(container.read(provider).hasError, isTrue);
    });
  }

  test('invalidation retries and recovers from an error', () async {
    when(
      list,
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'Offline')));
    await expectLater(
      container.read(provider.future),
      throwsA(isA<FailureException>()),
    );

    when(list).thenAnswer((_) async => Right([item]));
    container.invalidate(provider);

    expect(await container.read(provider.future), [item]);
    expect(container.read(provider).hasError, isFalse);
  });

  test('unexpected repository exceptions are not hidden', () async {
    final error = StateError('Unexpected repository failure');
    when(list).thenThrow(error);

    await expectLater(container.read(provider.future), throwsA(same(error)));
  });
}
