import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/home/presentation/providers/home_prefetch_provider.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';

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
        // Override the core providers with simple data to avoid actual DB loading
        learnerWordsProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerNumbersProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerSentencesProvider.overrideWith(
          (ref) => const AsyncValue.data([]),
        ),
        learnerLettersProvider.overrideWith((ref) => const AsyncValue.data([])),
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

        // Verify initial state
        final initialState = container.read(homePrefetchProvider);
        expect(initialState.isPrefetching, isFalse);
        expect(initialState.lastCategoryRefresh, isNull);

        // Call prefetch
        await notifier.prefetch();

        // Verify category refresh was called
        expect(mockCategoryNotifier.refreshCount, 1);

        // Verify state was updated with timestamp and isPrefetching became false
        final stateAfter = container.read(homePrefetchProvider);
        expect(stateAfter.isPrefetching, isFalse);
        expect(stateAfter.lastCategoryRefresh, isNotNull);
      },
    );

    test(
      'subsequent prefetch within threshold skips category refresh',
      () async {
        final notifier = container.read(homePrefetchProvider.notifier);

        // First prefetch
        await notifier.prefetch();
        expect(mockCategoryNotifier.refreshCount, 1);

        // Second prefetch immediately after
        await notifier.prefetch();

        // Verify refresh was NOT called again (still total of 1 call)
        expect(mockCategoryNotifier.refreshCount, 1);
      },
    );

    test('prefetch with forceRefresh: true bypasses staleness check', () async {
      final notifier = container.read(homePrefetchProvider.notifier);

      // First prefetch
      await notifier.prefetch();
      expect(mockCategoryNotifier.refreshCount, 1);

      // Second prefetch with forceRefresh
      await notifier.prefetch(forceRefresh: true);

      // Verify refresh WAS called again (total of 2 calls)
      expect(mockCategoryNotifier.refreshCount, 2);
    });
  });
}
