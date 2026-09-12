import 'package:flutter_riverpod/flutter_riverpod.dart';

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
