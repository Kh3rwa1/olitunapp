import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../profile/presentation/providers/user_stats_provider.dart';

/// Durable lesson completion IDs, loaded from the existing local-first profile
/// progress and Appwrite account-preferences sync.
final completedLessonIdsProvider = Provider<Set<String>>((ref) {
  final completed = ref.watch(
    userStatsProvider.select((stats) => stats.valueOrNull?.completedLessons),
  );
  if (completed == null || completed.isEmpty) return const <String>{};
  return Set<String>.unmodifiable(completed);
});

/// Lessons the learner unlocked early by watching a rewarded ad. Each entry
/// lifts the progression lock for that one lesson only (never a paywall),
/// and is kept on the device.
final adUnlockedLessonIdsProvider =
    NotifierProvider<AdUnlockedLessonIds, Set<String>>(AdUnlockedLessonIds.new);

class AdUnlockedLessonIds extends Notifier<Set<String>> {
  static const _prefsKey = 'ad_unlocked_lesson_ids';

  @override
  Set<String> build() {
    try {
      final saved = ref
          .read(sharedPreferencesProvider)
          .getStringList(_prefsKey);
      return Set<String>.unmodifiable(saved ?? const <String>[]);
    } catch (_) {
      return const <String>{};
    }
  }

  void unlock(String lessonId) {
    if (state.contains(lessonId)) return;
    state = Set<String>.unmodifiable({...state, lessonId});
    try {
      ref
          .read(sharedPreferencesProvider)
          .setStringList(_prefsKey, state.toList());
    } catch (_) {
      // Unlock still holds for this session.
    }
  }
}
