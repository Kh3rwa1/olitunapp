import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/progress_merge_crdt.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

/// Post-fix regression coverage for the folded-ledger representation.
///
/// All tests use the REAL merge implementation ([mergeProgressStats]) and
/// the REAL serialization ([UserStatsModel]). Covered: minutes parity with
/// stars, new/legacy mixtures, old (list) and new (map) wire shapes, restart
/// round-trips, repeated replay, merge orderings/groupings, reset
/// generations, over-threshold scale, and CRDT convergence properties.
UserStatsEntity _empty() {
  return const UserStatsEntity(
    practicedLetters: {},
    completedLessons: {},
    quizHistory: {},
    categoryMastery: {},
    totalLearningMinutes: 0,
    lastActiveDate: '',
    currentStreak: 0,
    totalStars: 0,
  );
}

UserStatsEntity _withStarEvents(Map<String, int> events, int totalStars) {
  return _empty().copyWith(starEvents: events, totalStars: totalStars);
}

void main() {
  final asOf = DateTime(2026, 9, 5, 12);

  /// Compaction as performed by the repository: merge a history into an
  /// empty accumulator, which folds overflow above the live-event cap.
  UserStatsEntity compact(UserStatsEntity history) {
    return mergeProgressStats(_empty(), history, asOf: asOf);
  }

  group('Case A: independently compacted legacy histories', () {
    test('two disjoint 101-event compacted histories merge to 202', () {
      final eventsA = {
        for (var i = 0; i < 101; i++) 'star_${1700000000000000 + i}': 1,
      };
      final eventsB = {
        for (var i = 0; i < 101; i++) 'star_${1700000100000000 + i}': 1,
      };
      final historyA = _withStarEvents(eventsA, 101);
      final historyB = _withStarEvents(eventsB, 101);

      // Sanity: direct merge of the UN-compacted maps is exact (202) and
      // does not reproduce the defect.
      final direct = mergeProgressStats(historyA, historyB, asOf: asOf);
      expect(direct.totalStars, 202);

      final compactA = compact(historyA);
      final compactB = compact(historyB);
      expect(compactA.totalStars, 101);
      expect(compactB.totalStars, 101);

      final merged = mergeProgressStats(compactA, compactB, asOf: asOf);
      expect(merged.totalStars, 202);
    });
  });

  group('Case B: stale replay after legacy compaction', () {
    test('replayed stale snapshot never re-credits folded events', () {
      final allKeys = [
        for (var i = 0; i < 601; i++) 'star_${1700000000000000 + i}',
      ];
      final history = _withStarEvents({for (final k in allKeys) k: 1}, 601);
      final compacted = compact(history);
      expect(compacted.totalStars, 601);

      UserStatsEntity staleSnapshot() =>
          _withStarEvents({for (final k in allKeys.take(100)) k: 1}, 100);

      final once = mergeProgressStats(compacted, staleSnapshot(), asOf: asOf);
      expect(once.totalStars, 601);

      final twice = mergeProgressStats(once, staleSnapshot(), asOf: asOf);
      expect(twice.totalStars, 601);
    });
  });

  group('Case C: unseen same-origin event below a checkpoint', () {
    test('late sequence 1 from the same origin is preserved', () {
      // Realistic installation origin/sequence ID format as issued by
      // ProgressOriginIdentity + recordStarReward.
      const origin = 'c_a1b2c3d4e5';
      final history = _withStarEvents({
        for (var seq = 2; seq <= 103; seq++) '${origin}_$seq': 1,
      }, 102);
      final compacted = compact(history);
      expect(compacted.totalStars, 102);

      final late = _withStarEvents({'${origin}_1': 1}, 1);
      final merged = mergeProgressStats(compacted, late, asOf: asOf);
      expect(merged.totalStars, 103);
    });
  });

  group('Minutes parity: same guarantees as stars', () {
    test('unseen same-origin minute below a gap is preserved', () {
      const origin = 'c_a1b2c3d4e5';
      final history = _empty().copyWith(
        minuteEvents: {
          for (var seq = 2; seq <= 103; seq++) '${origin}_$seq': 2,
        },
        totalLearningMinutes: 204,
      );
      final compacted = compact(history);
      expect(compacted.totalLearningMinutes, 204);

      final late = _empty().copyWith(
        minuteEvents: {'${origin}_1': 2},
        totalLearningMinutes: 2,
      );
      final merged = mergeProgressStats(compacted, late, asOf: asOf);
      expect(merged.totalLearningMinutes, 206);
    });

    test('independently compacted minute histories merge exactly', () {
      UserStatsEntity history(int base, int count) => _empty().copyWith(
        minuteEvents: {for (var i = 0; i < count; i++) 'min_${base}_$i': 2},
        totalLearningMinutes: count * 2,
      );
      final compactA = compact(history(1700000000000000, 101));
      final compactB = compact(history(1700000100000000, 101));
      final merged = mergeProgressStats(compactA, compactB, asOf: asOf);
      expect(merged.totalLearningMinutes, 404);
    });
  });

  group('New/legacy mixtures', () {
    test('sequenced and legacy events compact and merge exactly', () {
      const origin = 'c_a1b2c3d4e5';
      final sequenced = {
        for (var seq = 1; seq <= 50; seq++) '${origin}_$seq': 1,
      };
      final legacy = {
        for (var i = 0; i < 60; i++) 'star_${1700000000000000 + i}': 1,
      };
      final history = _withStarEvents({...sequenced, ...legacy}, 110);
      final compacted = compact(history);
      expect(compacted.totalStars, 110);
      expect(compacted.starEvents.length, lessThanOrEqualTo(100));
      // The 10 folded keys sort first (c_ < star_), forming the contiguous
      // prefix 1..10, which promotes to checkpoint+base.
      expect(compacted.starCheckpoints[origin], 10);
      expect(compacted.baseStarsByOrigin[origin], 10);

      // Stale snapshots of both kinds stay excluded on replay.
      final stale = _withStarEvents({
        '${origin}_7': 1,
        'star_1700000000000005': 1,
      }, 2);
      final once = mergeProgressStats(compacted, stale, asOf: asOf);
      expect(once.totalStars, 110);
      final twice = mergeProgressStats(once, stale, asOf: asOf);
      expect(twice.totalStars, 110);
    });
  });

  group('Serialization and restart', () {
    test('old list-shaped compacted sets migrate to exclusion markers', () {
      final json = {
        'practicedLetters': [],
        'completedLessons': [],
        'quizHistory': {},
        'categoryMastery': {},
        'totalLearningMinutes': 0,
        'lastActiveDate': '',
        'currentStreak': 0,
        'totalStars': 105,
        'starEvents': {
          for (var i = 5; i < 105; i++) 'star_${1700000000000000 + i}': 1,
        },
        // Pre-ledger wire shape: bare key list, values in baseStarsByOrigin.
        'compactedStarEvents': [
          for (var i = 0; i < 5; i++) 'star_${1700000000000000 + i}',
        ],
        'baseStarsByOrigin': {'__discrete__': 5},
      };
      final restored = UserStatsModel.fromJson(json);

      // Totals preserved exactly; old keys become zero-valued markers.
      expect(restored.totalStars, 105);
      expect(restored.foldedStarEvents['star_1700000000000000'], 0);
      expect(restored.foldedStarEvents.length, 5);

      // A stale replay of a migrated key is still excluded.
      final stale = _withStarEvents({'star_1700000000000000': 1}, 1);
      final merged = mergeProgressStats(restored, stale, asOf: asOf);
      expect(merged.totalStars, 105);
    });

    test('new map-shaped ledger round-trips with values intact', () {
      final history = _withStarEvents({
        for (var i = 0; i < 150; i++) 'star_${1700000000000000 + i}': 3,
      }, 450);
      final compacted = compact(history);
      expect(compacted.totalStars, 450);

      final encoded = jsonEncode(UserStatsModel.fromEntity(compacted).toJson());
      final restored = UserStatsModel.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(restored.totalStars, 450);
      expect(restored.foldedStarEvents, equals(compacted.foldedStarEvents));
      expect(restored.starEvents, equals(compacted.starEvents));

      // Restarted state merges stale snapshots exactly.
      final stale = _withStarEvents({'star_1700000000000000': 3}, 3);
      final merged = mergeProgressStats(restored, stale, asOf: asOf);
      expect(merged.totalStars, 450);
    });

    test('previous builds parse new payloads: list shape, exact totals', () {
      final history = _withStarEvents({
        for (var i = 0; i < 150; i++) 'star_${1700000000000000 + i}': 3,
      }, 450);
      final compacted = compact(history);
      final payload =
          jsonDecode(jsonEncode(UserStatsModel.fromEntity(compacted).toJson()))
              as Map<String, dynamic>;

      // The legacy key must stay a LIST: previous builds parse it verbatim
      // with `Set.from(...)`, which throws on any other shape.
      expect(payload['compactedStarEvents'], isA<List>());
      final legacySet = Set<String>.from(payload['compactedStarEvents'] ?? []);
      expect(
        legacySet,
        equals(Set<String>.of(compacted.foldedStarEvents.keys)),
      );

      // Previous-release total reconstruction (live sum plus the unattributed
      // remainder) stays exact on new payloads: the ledger values cover the
      // remainder unit-for-unit.
      final live = Map<String, dynamic>.from(payload['starEvents'] as Map);
      final liveSum = live.values.fold<int>(0, (s, v) => s + (v as int));
      final total = payload['totalStars'] as int;
      final remainder = total - liveSum;
      expect(remainder, greaterThanOrEqualTo(0));
      final ledger = Map<String, dynamic>.from(
        payload['foldedStarEvents'] as Map,
      );
      expect(ledger.values.fold<int>(0, (s, v) => s + (v as int)), remainder);
    });
  });

  group('Merge orderings, groupings, and generations', () {
    test('three-way merges converge regardless of grouping', () {
      UserStatsEntity history(int base) => _withStarEvents({
        for (var i = 0; i < 60; i++) 'star_${base + i}': 1,
      }, 60);
      final a = history(1700000000000000);
      final b = history(1700000000000060);
      final c = history(1700000000000120);

      final ab = mergeProgressStats(a, b, asOf: asOf);
      final abC = mergeProgressStats(ab, c, asOf: asOf);
      final bc = mergeProgressStats(b, c, asOf: asOf);
      final aBc = mergeProgressStats(a, bc, asOf: asOf);

      expect(abC.totalStars, 180);
      expect(aBc.totalStars, 180);
    });

    test('merging a state with itself is idempotent', () {
      final history = _withStarEvents({
        for (var i = 0; i < 150; i++) 'star_${1700000000000000 + i}': 2,
      }, 300);
      final compacted = compact(history);
      final again = mergeProgressStats(compacted, compacted, asOf: asOf);
      expect(again.totalStars, 300);
      expect(again.starEvents, equals(compacted.starEvents));
      expect(again.foldedStarEvents, equals(compacted.foldedStarEvents));
    });

    test('higher reset generation wins entirely', () {
      final old = _withStarEvents({'star_1': 5}, 5);
      final reset = _empty().copyWith(syncEpoch: 1);
      expect(
        mergeProgressStats(old, reset, asOf: asOf).totalStars,
        reset.totalStars,
      );
      expect(
        mergeProgressStats(reset, old, asOf: asOf).totalStars,
        reset.totalStars,
      );
    });
  });

  group('Over-threshold scale', () {
    test('1200 legacy events stay exact with bounded live maps', () {
      final keys = [
        for (var i = 0; i < 1200; i++) 'star_${1700000000000000 + i}',
      ];
      final history = _withStarEvents({for (final k in keys) k: 1}, 1200);
      final compacted = compact(history);
      expect(compacted.totalStars, 1200);
      expect(compacted.starEvents.length, lessThanOrEqualTo(100));

      final stale = _withStarEvents({
        for (final k in keys.take(100)) k: 1,
      }, 100);
      final once = mergeProgressStats(compacted, stale, asOf: asOf);
      expect(once.totalStars, 1200);
      final twice = mergeProgressStats(once, stale, asOf: asOf);
      expect(twice.totalStars, 1200);
    });
  });
}
