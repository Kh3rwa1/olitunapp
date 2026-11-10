// Word of the day: one deterministic pick from the existing word corpus per
// local calendar day. Same word on every device for the same day, no
// network, no new content.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/learner_content_providers.dart';
import 'today_activity_provider.dart';

/// Local days since the Unix epoch for [day] (date part only).
int daysSinceEpoch(DateTime day) {
  final local = DateTime(day.year, day.month, day.day);
  return local.difference(DateTime(1970)).inDays;
}

/// Picks the word for [day]: active words sorted by `order` then `id`,
/// indexed by the day number modulo the corpus size. Null for no words.
WordModel? pickWordOfDay(List<WordModel> words, DateTime day) {
  final active = words.where((w) => w.isActive).toList()
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  if (active.isEmpty) return null;
  final index = daysSinceEpoch(day) % active.length;
  return active[index < 0 ? index + active.length : index];
}

/// Today's word, or null while the corpus loads / when it is empty.
final wordOfDayProvider = Provider<WordModel?>((ref) {
  final words = ref.watch(learnerWordsProvider).valueOrNull;
  if (words == null) return null;
  return pickWordOfDay(words, ref.watch(todayActivityClockProvider)());
});
