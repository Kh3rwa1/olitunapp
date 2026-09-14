// Personalized review queue: scheduler urgency first, onboarding profile
// second. See [prioritizeReviewItems] for the ranking rules.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/language_settings_providers.dart';
import '../data/review_store.dart';
import '../domain/review_item.dart';
import 'review_exercise.dart';

/// Due items re-ranked for this learner. Synchronous off the loaded store;
/// empty while loading.
final personalizedDueItemsProvider = Provider<List<MemoryItemState>>((ref) {
  final due = ref.watch(dueReviewItemsProvider);
  final proficiency = ref.watch(santaliProficiencyProvider);
  final goals = ref.watch(learningGoalsProvider);
  return prioritizeReviewItems(due, proficiency: proficiency, goals: goals);
});
