import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/categories/presentation/providers/category_providers.dart';
import 'package:itun/shared/models/catalog/category_entity.dart';
import 'package:itun/shared/providers/content_providers.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

const _alphabets = CategoryEntity(
  id: 'alphabets',
  titleOlChiki: 'ᱚᱠᱷᱚᱨ',
  titleLatin: 'Alphabets',
);
const _numbers = CategoryEntity(
  id: 'numbers',
  titleOlChiki: 'ᱮᱞ',
  titleLatin: 'Numbers',
);

ProviderContainer _container(CategoryRepository repo) {
  final container = ProviderContainer(
    overrides: [
      categoryRepositoryProvider.overrideWithValue(repo),
      isAuthenticatedProvider.overrideWith((ref) => false),
    ],
  );
  addTearDown(container.dispose);
  // Keep the provider alive like a mounted screen would.
  container.listen(categoryNotifierProvider, (_, _) {});
  return container;
}

void main() {
  late _MockCategoryRepository repo;

  setUpAll(() => registerFallbackValue(_alphabets));
  setUp(() => repo = _MockCategoryRepository());

  test('build loads and de-duplicates by id and normalized title', () async {
    when(() => repo.getCategories()).thenAnswer(
      (_) async => const Right([
        _alphabets,
        _alphabets,
        CategoryEntity(id: 'dup', titleOlChiki: '', titleLatin: ' alphabets '),
        _numbers,
      ]),
    );
    final container = _container(repo);

    expect(container.read(categoryNotifierProvider).isLoading, isTrue);
    final items = await container.read(categoryNotifierProvider.future);
    expect(items.map((c) => c.id), ['alphabets', 'numbers']);
  });

  test(
    'a repository failure surfaces as AsyncError with the failure',
    () async {
      when(
        () => repo.getCategories(),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));
      final container = _container(repo);

      await expectLater(
        container.read(categoryNotifierProvider.future),
        throwsA(isA<FailureException>()),
      );
      final state = container.read(categoryNotifierProvider);
      expect(state.hasError, isTrue);
      expect((state.error! as FailureException).failure.message, 'offline');
    },
  );

  test('refresh keeps previous data visible and re-fetches', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets]));
    final container = _container(repo);
    await container.read(categoryNotifierProvider.future);

    final pending = Completer<Either<Failure, List<CategoryEntity>>>();
    when(() => repo.getCategories()).thenAnswer((_) => pending.future);
    final refresh = container.read(categoryNotifierProvider.notifier).refresh();

    // Previous data stays on screen without a loading flag (no spinner).
    final during = container.read(categoryNotifierProvider);
    expect(during.isLoading, isFalse);
    expect(during.value, [_alphabets]);

    pending.complete(const Right([_alphabets, _numbers]));
    await refresh;
    expect(container.read(categoryNotifierProvider).value, [
      _alphabets,
      _numbers,
    ]);
  });

  test('refresh failure does not throw and is reflected in state', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets]));
    final container = _container(repo);
    await container.read(categoryNotifierProvider.future);

    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'boom')));
    await container.read(categoryNotifierProvider.notifier).refresh();

    expect(container.read(categoryNotifierProvider).hasError, isTrue);
  });

  test('teaching language change rebuilds the catalog', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets]));
    final container = _container(repo);
    await container.read(categoryNotifierProvider.future);

    container.read(teachingLanguageRevisionProvider.notifier).state++;
    await container.read(categoryNotifierProvider.future);

    verify(() => repo.getCategories()).called(2);
  });

  test('successful mutations reload; failed ones do not', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets]));
    when(
      () => repo.createCategory(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repo.deleteCategory(any()),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'denied')));
    final container = _container(repo);
    await container.read(categoryNotifierProvider.future);
    final notifier = container.read(categoryNotifierProvider.notifier);

    await notifier.addCategory(_numbers);
    verify(() => repo.getCategories()).called(2);

    await notifier.deleteCategory('alphabets');
    verifyNever(() => repo.getCategories());
    expect(container.read(categoryNotifierProvider).value, [_alphabets]);
  });

  test('reorderCategories moves an item locally', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets, _numbers]));
    final container = _container(repo);
    await container.read(categoryNotifierProvider.future);

    await container
        .read(categoryNotifierProvider.notifier)
        .reorderCategories(0, 1);

    expect(container.read(categoryNotifierProvider).value, [
      _numbers,
      _alphabets,
    ]);
  });

  test('refresh resolves while nothing listens to the provider', () async {
    when(
      () => repo.getCategories(),
    ).thenAnswer((_) async => const Right([_alphabets]));
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        // Resolves after the first build, leaving a pending dependency
        // rebuild that only happens when someone listens.
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(categoryNotifierProvider.notifier)
        .refresh()
        .timeout(const Duration(seconds: 2));

    expect(await container.read(categoryNotifierProvider.future), [_alphabets]);
  });
}
