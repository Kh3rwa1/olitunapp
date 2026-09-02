import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
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

class HomePrefetchNotifier extends Notifier<HomePrefetchState> {
  bool _disposed = false;

  static const _stalenessThreshold = Duration(minutes: 5);

  @override
  HomePrefetchState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return HomePrefetchState(isPrefetching: false);
  }

  Future<void> prefetch({bool forceRefresh = false}) async {
    // 1. Trigger reading of core learner content providers
    ref.read(learnerWordsProvider);
    ref.read(learnerNumbersProvider);
    ref.read(learnerSentencesProvider);
    ref.read(learnerLettersProvider);

    // 2. Check category list staleness and refresh if needed
    final lastRefresh = state.lastCategoryRefresh;
    final now = DateTime.now();
    final isStale =
        lastRefresh == null ||
        now.difference(lastRefresh) > _stalenessThreshold;

    if (isStale || forceRefresh) {
      state = state.copyWith(isPrefetching: true);
      try {
        await ref.read(categoryNotifierProvider.notifier).refresh();
        if (_disposed) return;
        state = HomePrefetchState(
          isPrefetching: false,
          lastCategoryRefresh: DateTime.now(),
        );
      } catch (e) {
        AppLogger.debug('HomePrefetch: category refresh failed: $e');
        if (_disposed) return;
        state = state.copyWith(isPrefetching: false);
      }
    }
  }
}

final homePrefetchProvider =
    NotifierProvider<HomePrefetchNotifier, HomePrefetchState>(
      HomePrefetchNotifier.new,
    );
