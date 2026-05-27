import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/home/presentation/providers/home_prefetch_provider.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/models/content_models.dart';

class MockCategoryNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>>
    with Mock
    implements CategoryNotifier {
  MockCategoryNotifier() : super(const AsyncValue.data([]));
}

void main() {
  late MockCategoryNotifier mockCategoryNotifier;
  late ProviderContainer container;

  setUp(() {
    mockCategoryNotifier = MockCategoryNotifier();
    when(() => mockCategoryNotifier.refresh()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        categoryNotifierProvider.overrideWith((ref) => mockCategoryNotifier),
        // Override the core providers with simple data to avoid actual DB loading
        learnerWordsProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerNumbersProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerSentencesProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerLettersProvider.overrideWith((ref) => const AsyncValue.data([])),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HomePrefetchNotifier Tests', () {
    test('initial prefetch triggers category refresh and reads core contents', () async {
      final notifier = container.read(homePrefetchProvider.notifier);

      // Verify initial state
      final initialState = container.read(homePrefetchProvider);
      expect(initialState.isPrefetching, isFalse);
      expect(initialState.lastCategoryRefresh, isNull);

      // Call prefetch
      await notifier.prefetch();

      // Verify category refresh was called
      verify(() => mockCategoryNotifier.refresh()).called(1);

      // Verify state was updated with timestamp and isPrefetching became false
      final stateAfter = container.read(homePrefetchProvider);
      expect(stateAfter.isPrefetching, isFalse);
      expect(stateAfter.lastCategoryRefresh, isNotNull);
    });

    test('subsequent prefetch within threshold skips category refresh', () async {
      final notifier = container.read(homePrefetchProvider.notifier);

      // First prefetch
      await notifier.prefetch();
      verify(() => mockCategoryNotifier.refresh()).called(1);

      // Second prefetch immediately after
      await notifier.prefetch();

      // Verify refresh was NOT called again (still total of 1 call)
      verifyNever(() => mockCategoryNotifier.refresh());
    });

    test('prefetch with forceRefresh: true bypasses staleness check', () async {
      final notifier = container.read(homePrefetchProvider.notifier);

      // First prefetch
      await notifier.prefetch();
      verify(() => mockCategoryNotifier.refresh()).called(1);

      // Second prefetch with forceRefresh
      await notifier.prefetch(forceRefresh: true);

      // Verify refresh WAS called again (total of 2 calls)
      verify(() => mockCategoryNotifier.refresh()).called(1);
    });
  });
}
