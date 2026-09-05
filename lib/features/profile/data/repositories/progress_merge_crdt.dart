import 'dart:math' as math;
import '../../domain/entities/quiz_result_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/streak_week_logic.dart';

// ===========================================================================
// Progress merge representation and its invariants.
//
// Live events (`starEvents` / `minuteEvents`) hold unfolded reward deltas,
// capped at [maxLiveEvents]; overflow folds smallest-first into the folded
// ledger. Folded ledgers (`foldedStarEvents` / `foldedMinuteEvents`) hold
// EVERY folded event's key -> value and are counted in totals. Per-origin
// number bases (`baseStarsByOrigin` / `baseMinutesByOrigin`) hold ONLY sums
// of contiguous folded runs; per-origin checkpoints (`starCheckpoints` /
// `minuteCheckpoints`) record the proven contiguous folded prefix per
// origin: cp[O] = N means every sequence 1..N of O was folded (never merely
// "the largest sequence observed").
//
// Invariants (all merge operations preserve them):
// 1. Total = sum(bases) + sum(ledger) + sum(live). Totals are always
//    recomputed from these parts, never carried.
// 2. A live event K is counted iff K is absent from the ledger AND NOT
//    covered by a checkpoint (sequenced with seq <= cp[origin]). Folded
//    keys are therefore never re-credited, and unseen out-of-order events
//    below a checkpoint are never dropped.
// 3. Checkpoints advance only over contiguous folded runs starting at
//    (previous cp)+1. Gaps stay in the ledger until the missing sequences
//    arrive and fold, at which point promotion moves the run to base+cp.
// 4. Ledger entries are evicted ONLY when covered by a checkpoint. There
//    is no lossy numeric cap on uncovered entries: steady-state storage
//    stays tiny (checkpoints cover well-formed streams) while the bound
//    scales with the finite legacy universe plus reorder gaps, not with
//    total lifetime events.
// 5. Merge is idempotent, commutative, and total-convergent: every combiner
//    is a union or a per-key max over deterministic (sorted) folds.
// 6. Frozen legacy keys (`__legacy__`, `__discrete__`) are carried with
//    max-merge for backward compatibility and are NEVER written by merge.
//    All new folds go to the ledger with exact per-key values. Pre-existing
//    multi-device folded totals that the old representation already merged
//    cannot be reconstructed exactly; they are preserved as-is (see the
//    migration note below), never guessed or rewritten.
//
// Legacy migration honesty:
// - What recovers exactly: every event still present as a live key, every
//   folded key tracked in the ledger, every contiguous checkpoint prefix.
// - What is ambiguous: unattributed remainder totals (`totalStars` beyond
//   accounted parts) from pre-tracking versions, and pre-migration folded
//   contributions that the old shared-base representation already merged
//   with max(). These are preserved verbatim, not reconstructed.
// - Policy: migration never invents events and never overwrites learner
//   totals. Any stronger reconciliation (e.g. attributing ambiguous
//   remainders to a device) requires explicit owner approval.
// ===========================================================================

class ProgressEventKey {
  final String origin;
  final int? seq;
  final String rawId;

  const ProgressEventKey({required this.origin, this.seq, required this.rawId});
}

bool _isGenericUnsequencedOrigin(String origin) {
  final lower = origin.toLowerCase();
  return lower == 'star' ||
      lower == 'min' ||
      lower.startsWith('practice') ||
      lower.startsWith('lesson');
}

/// Installation origins issued by [ProgressOriginIdentity] look like
/// `c_<hex>` and are the only underscore-joined origins backed by a
/// persistent per-origin sequence counter. Numeric suffixes on any other
/// origin (legacy `star_<ts>`, test-style `devA_1`, ...) must NOT be read
/// as a safe sequential stream.
final RegExp _installationOriginPattern = RegExp(r'^c_[0-9a-fA-F]{1,64}$');

bool _isSequencedOrigin(String origin) {
  if (_isGenericUnsequencedOrigin(origin)) return false;
  return _installationOriginPattern.hasMatch(origin);
}

ProgressEventKey parseProgressEvent(String key) {
  if (key.contains(':')) {
    final idx = key.lastIndexOf(':');
    final suffix = key.substring(idx + 1);
    final seq = int.tryParse(suffix);
    final origin = key.substring(0, idx);
    if (seq != null &&
        seq >= 0 &&
        seq < 1000000000 &&
        !_isGenericUnsequencedOrigin(origin)) {
      return ProgressEventKey(origin: origin, seq: seq, rawId: key);
    }
  }
  if (key.contains('_')) {
    final idx = key.lastIndexOf('_');
    final suffix = key.substring(idx + 1);
    final seq = int.tryParse(suffix);
    final origin = key.substring(0, idx);
    if (seq != null &&
        seq >= 0 &&
        seq < 1000000000 &&
        _isSequencedOrigin(origin)) {
      return ProgressEventKey(origin: origin, seq: seq, rawId: key);
    }
  }
  return ProgressEventKey(origin: key, rawId: key);
}

/// Merged reward-stream parts shared by stars and learning minutes.
class _MergedRewardStream {
  final Map<String, int> live;
  final Map<String, int> ledger;
  final Map<String, int> bases;
  final Map<String, int> checkpoints;

  const _MergedRewardStream({
    required this.live,
    required this.ledger,
    required this.bases,
    required this.checkpoints,
  });

  int get total =>
      live.values.fold<int>(0, (s, v) => s + v) +
      ledger.values.fold<int>(0, (s, v) => s + v) +
      bases.values.fold<int>(0, (s, v) => s + v);
}

/// Overflow cap for live (unfolded) events. Folding is exact (values move
/// to the ledger), so the cap bounds the live map without losing rewards.
const int maxLiveEvents = 100;

int _compareEventKeys(String k1, String k2) {
  final p1 = parseProgressEvent(k1);
  final p2 = parseProgressEvent(k2);
  if (p1.origin == p2.origin && p1.seq != null && p2.seq != null) {
    return p1.seq!.compareTo(p2.seq!);
  }
  return k1.compareTo(k2);
}

_MergedRewardStream _mergeRewardStream({
  required Map<String, int> liveA,
  required Map<String, int> liveB,
  required Map<String, int> ledgerA,
  required Map<String, int> ledgerB,
  required Map<String, int> baseA,
  required Map<String, int> baseB,
  required Map<String, int> checkpointsA,
  required Map<String, int> checkpointsB,
}) {
  // Checkpoints: per-origin max. Each side's checkpoint is a proven
  // contiguous prefix, so the max of two proven prefixes is proven.
  final checkpoints = <String, int>{};
  for (final origin in {...checkpointsA.keys, ...checkpointsB.keys}) {
    checkpoints[origin] = math.max(
      checkpointsA[origin] ?? 0,
      checkpointsB[origin] ?? 0,
    );
  }

  // Bases: per-key max. Per-origin entries hold only contiguous-run sums,
  // which are deterministic for a given proven prefix, so max is exact.
  // Frozen legacy keys (__legacy__/__discrete__) flow through read-only.
  final bases = <String, int>{};
  for (final origin in {...baseA.keys, ...baseB.keys}) {
    bases[origin] = math.max(baseA[origin] ?? 0, baseB[origin] ?? 0);
  }

  // Ledger: per-key max. Same folded key on both sides is the same earning
  // counted once; disjoint folds both survive (never max-collapsed).
  final ledger = <String, int>{};
  for (final key in {...ledgerA.keys, ...ledgerB.keys}) {
    ledger[key] = math.max(ledgerA[key] ?? 0, ledgerB[key] ?? 0);
  }

  // Live: union, excluding folded keys (counted via ledger) and
  // checkpoint-covered sequences (counted via bases).
  final live = <String, int>{};
  for (final key in {...liveA.keys, ...liveB.keys}) {
    if (ledger.containsKey(key)) continue;
    final parsed = parseProgressEvent(key);
    final cp = parsed.seq != null ? checkpoints[parsed.origin] : null;
    if (cp != null && cp >= 1 && parsed.seq! <= cp) continue;
    live[key] = math.max(liveA[key] ?? 0, liveB[key] ?? 0);
  }

  // Overflow: fold smallest-first into the ledger with exact values.
  if (live.length > maxLiveEvents) {
    final sortedKeys = live.keys.toList()..sort(_compareEventKeys);
    for (var i = 0; i < sortedKeys.length - maxLiveEvents; i++) {
      final key = sortedKeys[i];
      final delta = live.remove(key) ?? 0;
      ledger[key] = math.max(ledger[key] ?? 0, delta);
    }
  }

  // Promotion: contiguous ledger runs become base+checkpoint, which keeps
  // the ledger small for well-formed streams and self-heals gaps when
  // missing sequences arrive and fold.
  final originsWithLedgerSeqs = <String>{};
  final ledgerSeqsByOrigin = <String, Set<int>>{};
  for (final key in ledger.keys) {
    final parsed = parseProgressEvent(key);
    if (parsed.seq != null && parsed.seq! >= 1) {
      originsWithLedgerSeqs.add(parsed.origin);
      ledgerSeqsByOrigin
          .putIfAbsent(parsed.origin, () => <int>{})
          .add(parsed.seq!);
    }
  }
  for (final origin in originsWithLedgerSeqs) {
    var frontier = checkpoints[origin] ?? 0;
    if (frontier < 0) frontier = 0;
    final seqs = ledgerSeqsByOrigin[origin]!;
    var promotedSum = 0;
    while (seqs.contains(frontier + 1)) {
      frontier += 1;
      final runKey = _ledgerKeyFor(origin, frontier, ledger);
      if (runKey != null) {
        promotedSum += ledger.remove(runKey) ?? 0;
      }
    }
    if (frontier > (checkpoints[origin] ?? 0)) {
      checkpoints[origin] = frontier;
      bases[origin] = (bases[origin] ?? 0) + promotedSum;
    }
  }

  // Eviction: drop ONLY checkpoint-covered ledger entries. Uncovered
  // entries (legacy folds, reorder gaps) are retained; the bound scales
  // with the finite legacy universe plus reorder windows, not with total
  // lifetime events (see file invariants).
  ledger.removeWhere((key, _) {
    final parsed = parseProgressEvent(key);
    if (parsed.seq == null || parsed.seq! < 1) return false;
    final cp = checkpoints[parsed.origin] ?? 0;
    return parsed.seq! <= cp;
  });

  return _MergedRewardStream(
    live: live,
    ledger: ledger,
    bases: bases,
    checkpoints: checkpoints,
  );
}

/// Finds the ledger key holding sequence [seq] of [origin], if present.
/// Raw keys are matched by parsed (origin, seq) identity.
String? _ledgerKeyFor(String origin, int seq, Map<String, int> ledger) {
  for (final key in ledger.keys) {
    final parsed = parseProgressEvent(key);
    if (parsed.origin == origin && parsed.seq == seq) return key;
  }
  return null;
}

UserStatsEntity mergeProgressStats(
  UserStatsEntity a,
  UserStatsEntity b, {
  required DateTime asOf,
}) {
  if (a.syncEpoch != b.syncEpoch) {
    return a.syncEpoch > b.syncEpoch ? a : b;
  }

  final letters = Set<String>.from(a.practicedLetters)
    ..addAll(b.practicedLetters);
  final lessons = Set<String>.from(a.completedLessons)
    ..addAll(b.completedLessons);

  final quizHistory = Map<String, QuizResultEntity>.from(a.quizHistory);
  b.quizHistory.forEach((key, resultB) {
    if (quizHistory.containsKey(key)) {
      final resultA = quizHistory[key]!;
      if (resultB.score > resultA.score) {
        quizHistory[key] = resultB;
      }
    } else {
      quizHistory[key] = resultB;
    }
  });

  // Repeat attempts append a new timestamped key per attempt and this map
  // is serialized into one prefs string + one Appwrite user pref — cap it
  // to the most recent entries so it can never overflow storage.
  const maxQuizHistoryEntries = 50;
  if (quizHistory.length > maxQuizHistoryEntries) {
    final recentKeys = quizHistory.keys.toList()
      ..sort(
        (x, y) =>
            quizHistory[y]!.completedAt.compareTo(quizHistory[x]!.completedAt),
      );
    quizHistory.removeWhere(
      (key, _) => !recentKeys.take(maxQuizHistoryEntries).contains(key),
    );
  }

  final categoryMastery = Map<String, int>.from(a.categoryMastery);
  b.categoryMastery.forEach((key, valB) {
    final valA = categoryMastery[key] ?? 0;
    categoryMastery[key] = valB > valA ? valB : valA;
  });

  // ==========================================
  // Star Rewards Merge
  // ==========================================
  Map<String, int> resolveBaseStars(UserStatsEntity stats) {
    if (stats.baseStarsByOrigin.isNotEmpty) {
      return Map<String, int>.from(stats.baseStarsByOrigin);
    }
    // Frozen read path for pre-ledger states: attribute only the remainder
    // that live events plus the folded ledger do not already account for.
    // Never invents coverage; ambiguous remainders stay under the shared
    // legacy key exactly as stored (see file invariants).
    final liveSum = stats.starEvents.values.fold<int>(0, (s, v) => s + v);
    final ledgerSum = stats.foldedStarEvents.values.fold<int>(
      0,
      (s, v) => s + v,
    );
    final accounted = liveSum + ledgerSum;
    final legacyBase = stats.totalStars >= accounted
        ? stats.totalStars - accounted
        : stats.totalStars;
    return legacyBase > 0 ? {'__legacy__': legacyBase} : {};
  }

  final stars = _mergeRewardStream(
    liveA: a.starEvents,
    liveB: b.starEvents,
    ledgerA: a.foldedStarEvents,
    ledgerB: b.foldedStarEvents,
    baseA: resolveBaseStars(a),
    baseB: resolveBaseStars(b),
    checkpointsA: a.starCheckpoints,
    checkpointsB: b.starCheckpoints,
  );

  // ====================================================
  // Learning Minutes Merge
  // ====================================================
  Map<String, int> resolveBaseMinutes(UserStatsEntity stats) {
    if (stats.baseMinutesByOrigin.isNotEmpty) {
      return Map<String, int>.from(stats.baseMinutesByOrigin);
    }
    final liveSum = stats.minuteEvents.values.fold<int>(0, (s, v) => s + v);
    final ledgerSum = stats.foldedMinuteEvents.values.fold<int>(
      0,
      (s, v) => s + v,
    );
    final accounted = liveSum + ledgerSum;
    final legacyBase = stats.totalLearningMinutes >= accounted
        ? stats.totalLearningMinutes - accounted
        : stats.totalLearningMinutes;
    return legacyBase > 0 ? {'__legacy__': legacyBase} : {};
  }

  final minutes = _mergeRewardStream(
    liveA: a.minuteEvents,
    liveB: b.minuteEvents,
    ledgerA: a.foldedMinuteEvents,
    ledgerB: b.foldedMinuteEvents,
    baseA: resolveBaseMinutes(a),
    baseB: resolveBaseMinutes(b),
    checkpointsA: a.minuteCheckpoints,
    checkpointsB: b.minuteCheckpoints,
  );

  String lastActiveDate = a.lastActiveDate;
  if (b.lastActiveDate.isNotEmpty) {
    if (lastActiveDate.isEmpty ||
        b.lastActiveDate.compareTo(lastActiveDate) > 0) {
      lastActiveDate = b.lastActiveDate;
    }
  }

  final practiceDates = Set<String>.from(a.practiceDates)
    ..addAll(b.practiceDates);

  final currentStreak = StreakWeekLogic.deriveStreak(
    practiceDates,
    asOf: asOf,
    lastActiveDate: lastActiveDate,
    fallbackStreak: math.max<int>(a.currentStreak, b.currentStreak),
  );

  return UserStatsEntity(
    practicedLetters: letters,
    completedLessons: lessons,
    quizHistory: quizHistory,
    categoryMastery: categoryMastery,
    completedMissionsDates: {
      ...a.completedMissionsDates,
      ...b.completedMissionsDates,
    },
    practiceDates: practiceDates,
    totalLearningMinutes: minutes.total,
    lastActiveDate: lastActiveDate,
    currentStreak: currentStreak,
    totalStars: stars.total,
    syncEpoch: a.syncEpoch,
    starEvents: stars.live,
    minuteEvents: minutes.live,
    foldedStarEvents: stars.ledger,
    foldedMinuteEvents: minutes.ledger,
    baseStarsByOrigin: stars.bases,
    starCheckpoints: stars.checkpoints,
    baseMinutesByOrigin: minutes.bases,
    minuteCheckpoints: minutes.checkpoints,
  );
}
