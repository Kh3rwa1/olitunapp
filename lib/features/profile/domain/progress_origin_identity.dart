import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/progress_merge_crdt.dart';
import 'entities/user_stats_entity.dart';

/// Manages persistent client/installation identity and strictly monotonic
/// sequence numbers per origin for progress events.
class ProgressOriginIdentity {
  static const originKey = 'progress_client_origin_id';
  static const starSeqPrefix = 'progress_seq_star_';
  static const minSeqPrefix = 'progress_seq_min_';

  /// Retrieves the persistent client origin ID, generating and persisting a
  /// new unique ID if not already present.
  static String getOrCreateOriginId(SharedPreferences prefs) {
    var id = prefs.getString(originKey);
    if (id == null || id.isEmpty) {
      id = 'c_${const Uuid().v4().replaceAll('-', '').substring(0, 10)}';
      prefs.setString(originKey, id);
    }
    return id;
  }

  /// Allocates the next strictly monotonic star event sequence for [originId].
  /// Takes the maximum of the stored local counter, the origin checkpoint in [current],
  /// and any active events in [current] to ensure sequence numbers never regress.
  static int nextStarSeq(
    SharedPreferences prefs,
    String originId,
    UserStatsEntity current,
  ) {
    final key = '$starSeqPrefix$originId';
    final localStored = prefs.getInt(key) ?? 0;
    int maxKnown = math.max(
      localStored,
      current.starCheckpoints[originId] ?? 0,
    );
    for (final k in current.starEvents.keys) {
      final parsed = parseProgressEvent(k);
      if (parsed.origin == originId && parsed.seq != null) {
        if (parsed.seq! > maxKnown) maxKnown = parsed.seq!;
      }
    }
    final next = maxKnown + 1;
    prefs.setInt(key, next);
    return next;
  }

  /// Allocates the next strictly monotonic learning minute sequence for [originId].
  static int nextMinuteSeq(
    SharedPreferences prefs,
    String originId,
    UserStatsEntity current,
  ) {
    final key = '$minSeqPrefix$originId';
    final localStored = prefs.getInt(key) ?? 0;
    int maxKnown = math.max(
      localStored,
      current.minuteCheckpoints[originId] ?? 0,
    );
    for (final k in current.minuteEvents.keys) {
      final parsed = parseProgressEvent(k);
      if (parsed.origin == originId && parsed.seq != null) {
        if (parsed.seq! > maxKnown) maxKnown = parsed.seq!;
      }
    }
    final next = maxKnown + 1;
    prefs.setInt(key, next);
    return next;
  }
}
