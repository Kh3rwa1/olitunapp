// Pure bookkeeping for a finished daily practice session: stars, measured
// minutes, and which item ids to mark as recently seen.

import 'package:shared_preferences/shared_preferences.dart';

import '../../../review/presentation/review_exercise.dart';
import 'daily_practice_builder.dart';

/// Stars per correct card. Matches the review session's per-item award.
const int dailyPracticeStarsPerCorrect = 10;

/// One answered card.
typedef AnsweredCard = ({ReviewCard card, bool correct});

class DailyPracticeOutcome {
  const DailyPracticeOutcome({
    required this.stars,
    required this.minutes,
    required this.seenIds,
    required this.correctCount,
    required this.total,
  });

  final int stars;

  /// Measured session length rounded up; at least 1 when anything was
  /// answered (a learner who finished a session spent real time on it).
  final int minutes;
  final List<String> seenIds;
  final int correctCount;
  final int total;

  /// [elapsed] is the wall-clock time between the first card and the last
  /// answer. Stars: [dailyPracticeStarsPerCorrect] per correct card.
  factory DailyPracticeOutcome.from(
    List<AnsweredCard> answered, {
    required Duration elapsed,
  }) {
    final correct = answered.where((a) => a.correct).length;
    final wholeMinutes = elapsed.inSeconds <= 0
        ? 0
        : (elapsed.inSeconds / 60).ceil();
    return DailyPracticeOutcome(
      stars: correct * dailyPracticeStarsPerCorrect,
      minutes: answered.isEmpty ? 0 : (wholeMinutes < 1 ? 1 : wholeMinutes),
      seenIds: answered.map((a) => a.card.itemId).toSet().toList(),
      correctCount: correct,
      total: answered.length,
    );
  }

  /// Ids safe to hand to the review store (letters are excluded).
  List<String> get reviewStoreIds =>
      seenIds.where((id) => !id.startsWith(letterItemIdPrefix)).toList();
}

/// Ids shown in recent daily sessions (`daily_practice_recent_ids`, newest
/// last, capped at [limit]) so the fresh fill rotates through the corpus.
class RecentPracticeLog {
  RecentPracticeLog(this._prefs);

  static const String key = 'daily_practice_recent_ids';
  static const int limit = 60;

  final SharedPreferences _prefs;

  Set<String> ids() => (_prefs.getStringList(key) ?? const []).toSet();

  Future<void> markSeen(Iterable<String> seen) async {
    final current = _prefs.getStringList(key) ?? <String>[];
    final merged = [...current.where((id) => !seen.contains(id)), ...seen];
    final trimmed = merged.length > limit
        ? merged.sublist(merged.length - limit)
        : merged;
    await _prefs.setStringList(key, trimmed);
  }

  Future<void> clear() => _prefs.remove(key);
}
