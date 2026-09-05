import 'dart:math' as math;
import '../../domain/entities/quiz_result_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/streak_week_logic.dart';

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
        !_isGenericUnsequencedOrigin(origin)) {
      return ProgressEventKey(origin: origin, seq: seq, rawId: key);
    }
  }
  final match = RegExp(r'^([a-zA-Z0-9_-]+?)(\d+)$').firstMatch(key);
  if (match != null) {
    final origin = match.group(1)!;
    final seq = int.tryParse(match.group(2)!);
    if (seq != null &&
        seq >= 0 &&
        seq < 1000000000 &&
        !_isGenericUnsequencedOrigin(origin)) {
      return ProgressEventKey(origin: origin, seq: seq, rawId: key);
    }
  }
  return ProgressEventKey(origin: key, rawId: key);
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
  // Vector Checkpoint CRDT: Star Rewards Merge
  // ==========================================
  Map<String, int> resolveBaseStars(UserStatsEntity stats) {
    if (stats.baseStarsByOrigin.isNotEmpty) {
      return Map<String, int>.from(stats.baseStarsByOrigin);
    }
    final sumEvents = stats.starEvents.values.fold<int>(0, (s, v) => s + v);
    final legacyBase = stats.totalStars >= sumEvents
        ? stats.totalStars - sumEvents
        : stats.totalStars;
    return legacyBase > 0 ? {'__legacy__': legacyBase} : {};
  }

  final baseStarsA = resolveBaseStars(a);
  final baseStarsB = resolveBaseStars(b);

  final mergedStarCheckpoints = <String, int>{};
  final allStarCheckpointOrigins = {
    ...a.starCheckpoints.keys,
    ...b.starCheckpoints.keys,
  };
  for (final origin in allStarCheckpointOrigins) {
    final cpA = a.starCheckpoints[origin];
    final cpB = b.starCheckpoints[origin];
    if (cpA != null && cpB != null) {
      mergedStarCheckpoints[origin] = math.max(cpA, cpB);
    } else {
      mergedStarCheckpoints[origin] = (cpA ?? cpB)!;
    }
  }

  final mergedBaseStarsByOrigin = <String, int>{};
  final allBaseStarOrigins = {...baseStarsA.keys, ...baseStarsB.keys};
  for (final origin in allBaseStarOrigins) {
    final baseA = baseStarsA[origin] ?? 0;
    final baseB = baseStarsB[origin] ?? 0;
    mergedBaseStarsByOrigin[origin] = math.max(baseA, baseB);
  }

  final allCompactedStarEvents = Set<String>.from(a.compactedStarEvents)
    ..addAll(b.compactedStarEvents);

  final mergedStarEvents = <String, int>{};
  final allStarEventKeys = {...a.starEvents.keys, ...b.starEvents.keys};
  for (final key in allStarEventKeys) {
    if (allCompactedStarEvents.contains(key)) {
      continue;
    }
    final parsed = parseProgressEvent(key);
    if (parsed.seq != null &&
        mergedStarCheckpoints.containsKey(parsed.origin)) {
      final cp = mergedStarCheckpoints[parsed.origin]!;
      if (parsed.seq! <= cp) {
        // Already folded into base by this origin's monotonic checkpoint
        continue;
      }
    }
    final valA = a.starEvents[key] ?? 0;
    final valB = b.starEvents[key] ?? 0;
    mergedStarEvents[key] = math.max(valA, valB);
  }

  const maxEvents = 100;
  const maxCompactedTracking = 500;
  if (mergedStarEvents.length > maxEvents) {
    final sortedKeys = mergedStarEvents.keys.toList()
      ..sort((k1, k2) {
        final p1 = parseProgressEvent(k1);
        final p2 = parseProgressEvent(k2);
        if (p1.origin == p2.origin && p1.seq != null && p2.seq != null) {
          return p1.seq!.compareTo(p2.seq!);
        }
        return k1.compareTo(k2);
      });
    final overflowCount = mergedStarEvents.length - maxEvents;
    for (int i = 0; i < overflowCount; i++) {
      final key = sortedKeys[i];
      final delta = mergedStarEvents.remove(key) ?? 0;
      final parsed = parseProgressEvent(key);
      if (parsed.seq != null) {
        mergedStarCheckpoints[parsed.origin] = math.max(
          mergedStarCheckpoints[parsed.origin] ?? parsed.seq!,
          parsed.seq!,
        );
        mergedBaseStarsByOrigin[parsed.origin] =
            (mergedBaseStarsByOrigin[parsed.origin] ?? 0) + delta;
      } else {
        mergedBaseStarsByOrigin['__discrete__'] =
            (mergedBaseStarsByOrigin['__discrete__'] ?? 0) + delta;
      }
      allCompactedStarEvents.add(key);
    }
  }

  if (allCompactedStarEvents.length > maxCompactedTracking) {
    final sortedCompacted = allCompactedStarEvents.toList()..sort();
    allCompactedStarEvents.retainAll(
      sortedCompacted.sublist(sortedCompacted.length - maxCompactedTracking),
    );
  }

  final int totalStars =
      mergedBaseStarsByOrigin.values.fold<int>(0, (sum, val) => sum + val) +
      mergedStarEvents.values.fold<int>(0, (sum, val) => sum + val);

  // ====================================================
  // Vector Checkpoint CRDT: Learning Minutes Merge
  // ====================================================
  Map<String, int> resolveBaseMinutes(UserStatsEntity stats) {
    if (stats.baseMinutesByOrigin.isNotEmpty) {
      return Map<String, int>.from(stats.baseMinutesByOrigin);
    }
    final sumEvents = stats.minuteEvents.values.fold<int>(0, (s, v) => s + v);
    final legacyBase = stats.totalLearningMinutes >= sumEvents
        ? stats.totalLearningMinutes - sumEvents
        : stats.totalLearningMinutes;
    return legacyBase > 0 ? {'__legacy__': legacyBase} : {};
  }

  final baseMinutesA = resolveBaseMinutes(a);
  final baseMinutesB = resolveBaseMinutes(b);

  final mergedMinuteCheckpoints = <String, int>{};
  final allMinuteCheckpointOrigins = {
    ...a.minuteCheckpoints.keys,
    ...b.minuteCheckpoints.keys,
  };
  for (final origin in allMinuteCheckpointOrigins) {
    final cpA = a.minuteCheckpoints[origin];
    final cpB = b.minuteCheckpoints[origin];
    if (cpA != null && cpB != null) {
      mergedMinuteCheckpoints[origin] = math.max(cpA, cpB);
    } else {
      mergedMinuteCheckpoints[origin] = (cpA ?? cpB)!;
    }
  }

  final mergedBaseMinutesByOrigin = <String, int>{};
  final allBaseMinuteOrigins = {...baseMinutesA.keys, ...baseMinutesB.keys};
  for (final origin in allBaseMinuteOrigins) {
    final baseA = baseMinutesA[origin] ?? 0;
    final baseB = baseMinutesB[origin] ?? 0;
    mergedBaseMinutesByOrigin[origin] = math.max(baseA, baseB);
  }

  final allCompactedMinuteEvents = Set<String>.from(a.compactedMinuteEvents)
    ..addAll(b.compactedMinuteEvents);

  final mergedMinuteEvents = <String, int>{};
  final allMinuteEventKeys = {...a.minuteEvents.keys, ...b.minuteEvents.keys};
  for (final key in allMinuteEventKeys) {
    if (allCompactedMinuteEvents.contains(key)) {
      continue;
    }
    final parsed = parseProgressEvent(key);
    if (parsed.seq != null &&
        mergedMinuteCheckpoints.containsKey(parsed.origin)) {
      final cp = mergedMinuteCheckpoints[parsed.origin]!;
      if (parsed.seq! <= cp) {
        continue;
      }
    }
    final valA = a.minuteEvents[key] ?? 0;
    final valB = b.minuteEvents[key] ?? 0;
    mergedMinuteEvents[key] = math.max(valA, valB);
  }

  if (mergedMinuteEvents.length > maxEvents) {
    final sortedKeys = mergedMinuteEvents.keys.toList()
      ..sort((k1, k2) {
        final p1 = parseProgressEvent(k1);
        final p2 = parseProgressEvent(k2);
        if (p1.origin == p2.origin && p1.seq != null && p2.seq != null) {
          return p1.seq!.compareTo(p2.seq!);
        }
        return k1.compareTo(k2);
      });
    final overflowCount = mergedMinuteEvents.length - maxEvents;
    for (int i = 0; i < overflowCount; i++) {
      final key = sortedKeys[i];
      final delta = mergedMinuteEvents.remove(key) ?? 0;
      final parsed = parseProgressEvent(key);
      if (parsed.seq != null) {
        mergedMinuteCheckpoints[parsed.origin] = math.max(
          mergedMinuteCheckpoints[parsed.origin] ?? parsed.seq!,
          parsed.seq!,
        );
        mergedBaseMinutesByOrigin[parsed.origin] =
            (mergedBaseMinutesByOrigin[parsed.origin] ?? 0) + delta;
      } else {
        mergedBaseMinutesByOrigin['__discrete__'] =
            (mergedBaseMinutesByOrigin['__discrete__'] ?? 0) + delta;
      }
      allCompactedMinuteEvents.add(key);
    }
  }

  if (allCompactedMinuteEvents.length > maxCompactedTracking) {
    final sortedCompacted = allCompactedMinuteEvents.toList()..sort();
    allCompactedMinuteEvents.retainAll(
      sortedCompacted.sublist(sortedCompacted.length - maxCompactedTracking),
    );
  }

  final int totalLearningMinutes =
      mergedBaseMinutesByOrigin.values.fold<int>(0, (sum, val) => sum + val) +
      mergedMinuteEvents.values.fold<int>(0, (sum, val) => sum + val);

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
    totalLearningMinutes: totalLearningMinutes,
    lastActiveDate: lastActiveDate,
    currentStreak: currentStreak,
    totalStars: totalStars,
    syncEpoch: a.syncEpoch,
    starEvents: mergedStarEvents,
    minuteEvents: mergedMinuteEvents,
    compactedStarEvents: allCompactedStarEvents,
    compactedMinuteEvents: allCompactedMinuteEvents,
    baseStarsByOrigin: mergedBaseStarsByOrigin,
    starCheckpoints: mergedStarCheckpoints,
    baseMinutesByOrigin: mergedBaseMinutesByOrigin,
    minuteCheckpoints: mergedMinuteCheckpoints,
  );
}
