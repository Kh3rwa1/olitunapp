import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_service.dart';

const String _prefsKey = 'listened_bakhed_ids';

/// Local-first record of Bakhed items the learner has listened to at least
/// 80% through. Written by [RhymeAudioNotifier] when playback crosses the
/// completion threshold; read by catalogue cards to show a heard badge.
///
/// Deliberately device-local (no sync): it powers a lightweight "heard"
/// affordance, not progress that must survive device loss.
class ListenedBakhedNotifier extends Notifier<Set<String>> {
  bool _disposed = false;

  @override
  Set<String> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final ids = prefs.getStringList(_prefsKey) ?? const [];
      if (_disposed) return;
      state = Set<String>.from(ids);
    } catch (_) {
      // Badge data is best-effort; never block the catalogue on it.
    }
  }

  Future<void> markListened(String bakhedId) async {
    if (state.contains(bakhedId)) return;
    final next = Set<String>.from(state)..add(bakhedId);
    state = next;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_prefsKey, next.toList());
    } catch (_) {
      // In-memory state already updated; persistence is best-effort.
    }
  }
}

final listenedBakhedProvider =
    NotifierProvider<ListenedBakhedNotifier, Set<String>>(
      ListenedBakhedNotifier.new,
    );
