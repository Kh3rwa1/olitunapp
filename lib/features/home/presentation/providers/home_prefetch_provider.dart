import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/learner_content_providers.dart';
import '../../../categories/presentation/providers/category_notifier.dart';

class HomePrefetchState {
  final bool isPrefetching;
  final DateTime? lastCategoryRefresh;

  HomePrefetchState({required this.isPrefetching, this.lastCategoryRefresh});

  HomePrefetchState copyWith({
    bool? isPrefetching,
    DateTime? lastCategoryRefresh,
  }) {
    return HomePrefetchState(
      isPrefetching: isPrefetching ?? this.isPrefetching,
      lastCategoryRefresh: lastCategoryRefresh ?? this.lastCategoryRefresh,
    );
  }
}

class HomePrefetchNotifier extends StateNotifier<HomePrefetchState> {
  final Ref _ref;
  static const _stalenessThreshold = Duration(minutes: 5);

  HomePrefetchNotifier(this._ref)
    : super(HomePrefetchState(isPrefetching: false));

  Future<void> prefetch({bool forceRefresh = false}) async {
    // 1. Trigger reading of core learner content providers
    _ref.read(learnerWordsProvider);
    _ref.read(learnerNumbersProvider);
    _ref.read(learnerSentencesProvider);
    _ref.read(learnerLettersProvider);

    // 2. Check category list staleness and refresh if needed
    final lastRefresh = state.lastCategoryRefresh;
    final now = DateTime.now();
    final isStale =
        lastRefresh == null ||
        now.difference(lastRefresh) > _stalenessThreshold;

    if (isStale || forceRefresh) {
      state = state.copyWith(isPrefetching: true);
      try {
        await _ref.read(categoryNotifierProvider.notifier).refresh();
        if (!mounted) return;
        state = HomePrefetchState(
          isPrefetching: false,
          lastCategoryRefresh: DateTime.now(),
        );
      } catch (_) {
        if (!mounted) return;
        state = state.copyWith(isPrefetching: false);
      }
    }
  }
}

final homePrefetchProvider =
    StateNotifierProvider<HomePrefetchNotifier, HomePrefetchState>((ref) {
      return HomePrefetchNotifier(ref);
    });
