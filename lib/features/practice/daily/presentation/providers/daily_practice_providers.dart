// Riverpod wiring for daily practice. The screen (wave 3) reads
// [dailyPracticeCardsProvider] for its cards and calls
// [finishDailyPractice] with the answered cards when the session ends.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/storage/hive_service.dart';
import '../../../../../shared/providers/learner_content_providers.dart';
import '../../../../home/presentation/providers/today_activity_provider.dart';
import '../../../../home/presentation/providers/word_of_day_provider.dart';
import '../../../../profile/presentation/providers/user_stats_provider.dart';
import '../../../../quiz/presentation/providers/mistake_provider.dart';
import '../../../../review/presentation/review_exercise.dart';
import '../../../../review/presentation/review_queue_provider.dart';
import '../daily_practice_builder.dart';
import '../daily_practice_outcome.dart';

/// Random source for the session shuffle. Test override.
final dailyPracticeRngProvider = Provider<Random>((ref) => Random());

final recentPracticeLogProvider = Provider<RecentPracticeLog>(
  (ref) => RecentPracticeLog(ref.watch(sharedPreferencesProvider)),
);

/// Optional word id to put first (defaults to the word of the day).
/// Set to '' to disable seeding.
final dailyPracticeSeedWordProvider = StateProvider<String?>((ref) => null);

/// Cards for today's session. Loading while any corpus list is loading;
/// an error only when every corpus list failed (a partial corpus still
/// yields a usable session).
final dailyPracticeCardsProvider = Provider<AsyncValue<List<ReviewCard>>>((
  ref,
) {
  final words = ref.watch(learnerWordsProvider);
  final sentences = ref.watch(learnerSentencesProvider);
  final letters = ref.watch(learnerLettersProvider);
  if (words.isLoading || sentences.isLoading || letters.isLoading) {
    return const AsyncValue.loading();
  }
  if (words.hasError && sentences.hasError && letters.hasError) {
    return AsyncValue.error(
      words.error ?? StateError('corpus unavailable'),
      words.stackTrace ?? StackTrace.current,
    );
  }
  final seedOverride = ref.watch(dailyPracticeSeedWordProvider);
  final seedWordId = seedOverride ?? ref.watch(wordOfDayProvider)?.id;
  final cards = DailyPracticeBuilder.build(
    due: ref.watch(personalizedDueItemsProvider),
    mistakes: ref.watch(mistakeProvider),
    words: words.valueOrNull ?? const [],
    sentences: sentences.valueOrNull ?? const [],
    letters: letters.valueOrNull ?? const [],
    recentlySeenIds: ref.watch(recentPracticeLogProvider).ids(),
    rng: ref.watch(dailyPracticeRngProvider),
    seedWordId: (seedWordId == null || seedWordId.isEmpty) ? null : seedWordId,
  );
  return AsyncValue.data(cards);
});

/// Records a finished session: stars to the learner, measured minutes to
/// the daily goal log, ids to the recent log. Returns the outcome so the
/// screen can show it. Review-store updates stay with the screen (it
/// already knows how to grade individual recalls).
typedef DailyPracticeFinisher =
    Future<DailyPracticeOutcome> Function({
      required List<AnsweredCard> answered,
      required Duration elapsed,
    });

final dailyPracticeFinisherProvider = Provider<DailyPracticeFinisher>((ref) {
  return ({required answered, required elapsed}) async {
    final outcome = DailyPracticeOutcome.from(answered, elapsed: elapsed);
    if (outcome.stars > 0) {
      await ref.read(userStatsProvider.notifier).addStars(outcome.stars);
    }
    if (outcome.minutes > 0) {
      await ref.read(todayMinutesProvider.notifier).add(outcome.minutes);
    }
    if (outcome.seenIds.isNotEmpty) {
      await ref.read(recentPracticeLogProvider).markSeen(outcome.seenIds);
    }
    return outcome;
  };
});
