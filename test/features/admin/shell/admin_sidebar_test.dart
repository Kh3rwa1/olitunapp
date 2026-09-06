import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/home/presentation/providers/home_prefetch_provider.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class MockCategoryNotifier extends CategoryNotifier {
  int refreshCount = 0;

  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([]);

  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}

void main() {
  late MockCategoryNotifier mockCategoryNotifier;
  late ProviderContainer container;

  setUp(() {
    mockCategoryNotifier = MockCategoryNotifier();
    container = ProviderContainer(
      overrides: [
        categoryNotifierProvider.overrideWith(() => mockCategoryNotifier),
        // Mock the actual awaited sources, not only their derived UI providers.
        for (final kind in [
          ContentKind.word,
          ContentKind.number,
          ContentKind.sentence,
          ContentKind.letter,
        ])
          contentListProvider((kind, null)).overrideWith((ref) async => []),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HomePrefetchNotifier Tests', () {
    test(
      'initial prefetch triggers category refresh and reads core contents',
      () async {
        final notifier = container.read(homePrefetchProvider.notifier);
        final initialState = container.read(homePrefetchProvider);
        expect(initialState.isPrefetching, isFalse);
        expect(initialState.lastCategoryRefresh, isNull);
        await notifier.prefetch();
        expect(mockCategoryNotifier.refreshCount, 1);
        final stateAfter = container.read(homePrefetchProvider);
        expect(stateAfter.isPrefetching, isFalse);
        expect(stateAfter.lastCategoryRefresh, isNotNull);
      },
    );

    test(
      'subsequent prefetch within threshold skips category refresh',
      () async {
        final notifier = container.read(homePrefetchProvider.notifier);
        await notifier.prefetch();
        expect(mockCategoryNotifier.refreshCount, 1);
        await notifier.prefetch();
        expect(mockCategoryNotifier.refreshCount, 1);
      },
    );

    test('prefetch with forceRefresh: true bypasses staleness check', () async {
      final notifier = container.read(homePrefetchProvider.notifier);
      await notifier.prefetch();
      expect(mockCategoryNotifier.refreshCount, 1);
      await notifier.prefetch(forceRefresh: true);
      expect(mockCategoryNotifier.refreshCount, 2);
    });
  });
}
