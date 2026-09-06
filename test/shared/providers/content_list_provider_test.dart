import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class MockContentRepository extends Mock implements ContentRepository {}

void main() {
  late MockContentRepository repository;
  late ProviderContainer container;

  setUp(() async {
    repository = MockContentRepository();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    // Settle authentication before measuring content calls.
    await container.read(isAuthenticatedProvider.future);
  });

  tearDown(() => container.dispose());

  for (final failure in <Failure>[
    const NetworkFailure(),
    const CacheFailure(message: 'No offline content available'),
    const ServerFailure(message: 'Content service unavailable', code: 503),
    const AuthFailure(message: 'Session expired'),
  ]) {
    test('${failure.runtimeType} stays an error, not empty data', () async {
      when(
        () => repository.list(ContentKind.word, categoryId: 'vocab'),
      ).thenAnswer((_) async => Left(failure));
      final provider = contentListProvider((ContentKind.word, 'vocab'));

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
      expect(container.read(provider).valueOrNull, isNull);
    });
  }

  for (final kind in ContentKind.values) {
    test('empty successful ${kind.name} catalog remains data', () async {
      when(
        () => repository.list(kind),
      ).thenAnswer((_) async => const Right(<ContentItem>[]));
      final provider = contentListProvider((kind, null));

      expect(await container.read(provider.future), isEmpty);
      expect(container.read(provider).hasError, isFalse);
      expect(container.read(provider).asData, isNotNull);
    });
  }

  test('fallback content and category scope are preserved', () async {
    final items = [
      ContentItem(
        id: 'cached_word',
        kind: ContentKind.word,
        categoryId: 'vocab',
        title: 'Cached vocabulary',
        blocks: const [],
        updatedAt: DateTime(2026, 9, 6),
      ),
    ];
    when(
      () => repository.list(ContentKind.word, categoryId: 'vocab'),
    ).thenAnswer((_) async => Right(items));
    final provider = contentListProvider((ContentKind.word, 'vocab'));

    expect(await container.read(provider.future), same(items));
    expect(container.read(provider).hasError, isFalse);
    verify(
      () => repository.list(ContentKind.word, categoryId: 'vocab'),
    ).called(1);
  });

  test('retry clears the error after a successful fetch', () async {
    when(
      () => repository.list(ContentKind.word),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final provider = contentListProvider((ContentKind.word, null));
    await expectLater(
      container.read(provider.future),
      throwsA(isA<FailureException>()),
    );

    when(
      () => repository.list(ContentKind.word),
    ).thenAnswer((_) async => const Right(<ContentItem>[]));
    container.invalidate(provider);

    expect(await container.read(provider.future), isEmpty);
    expect(container.read(provider).hasError, isFalse);
    expect(container.read(provider).asData, isNotNull);
    verify(() => repository.list(ContentKind.word)).called(2);
  });
}
