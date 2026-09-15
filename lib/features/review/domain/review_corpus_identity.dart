// Corpus identity registry and review state reconciliation.
//
// Protects item-level learning progress from corpus renames, deletions, and
// orphan states without guessing or inferring identities from text similarity.
// Offline-first, deterministic, and idempotent.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import 'review_item.dart';

final corpusIdentityMapProvider = FutureProvider<ReviewCorpusIdentityMap>((
  ref,
) async {
  return ReviewCorpusIdentityMap.loadBundled();
});

class ReviewIdAlias {
  final ReviewItemType itemType;
  final String from;
  final String to;
  final String? reason;

  const ReviewIdAlias({
    required this.itemType,
    required this.from,
    required this.to,
    this.reason,
  });

  factory ReviewIdAlias.fromMap(Map<String, dynamic> map) {
    return ReviewIdAlias(
      itemType: ReviewItemTypeX.fromJson(map['itemType'] as String?),
      from: (map['from'] as String? ?? '').trim(),
      to: (map['to'] as String? ?? '').trim(),
      reason: map['reason'] as String?,
    );
  }
}

class ReviewIdTombstone {
  final ReviewItemType itemType;
  final String id;
  final String? reason;

  const ReviewIdTombstone({
    required this.itemType,
    required this.id,
    this.reason,
  });

  factory ReviewIdTombstone.fromMap(Map<String, dynamic> map) {
    return ReviewIdTombstone(
      itemType: ReviewItemTypeX.fromJson(map['itemType'] as String?),
      id: (map['id'] as String? ?? '').trim(),
      reason: map['reason'] as String?,
    );
  }
}

class ReviewIdMigrationManifest {
  final int schemaVersion;
  final List<ReviewIdAlias> aliases;
  final List<ReviewIdTombstone> tombstones;
  final bool isDegraded;

  const ReviewIdMigrationManifest({
    required this.schemaVersion,
    required this.aliases,
    required this.tombstones,
    this.isDegraded = false,
  });

  factory ReviewIdMigrationManifest.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int?;
    if (version == null || version != 1) {
      AppLogger.error(
        'ReviewIdMigrationManifest: unsupported schemaVersion: $version (expected 1)',
      );
      return ReviewIdMigrationManifest.degraded;
    }
    final aliasesRaw = json['aliases'] as List<dynamic>? ?? const [];
    final tombstonesRaw = json['tombstones'] as List<dynamic>? ?? const [];

    return ReviewIdMigrationManifest(
      schemaVersion: version,
      aliases: aliasesRaw
          .whereType<Map>()
          .map((m) => ReviewIdAlias.fromMap(Map<String, dynamic>.from(m)))
          .where((a) => a.from.isNotEmpty && a.to.isNotEmpty && a.from != a.to)
          .toList(growable: false),
      tombstones: tombstonesRaw
          .whereType<Map>()
          .map((m) => ReviewIdTombstone.fromMap(Map<String, dynamic>.from(m)))
          .where((t) => t.id.isNotEmpty)
          .toList(growable: false),
    );
  }

  static const empty = ReviewIdMigrationManifest(
    schemaVersion: 1,
    aliases: [],
    tombstones: [],
  );

  static const degraded = ReviewIdMigrationManifest(
    schemaVersion: 1,
    aliases: [],
    tombstones: [],
    isDegraded: true,
  );
}

enum CorpusAvailabilityState {
  ready,
  corpusAvailableManifestUnavailable,
  corpusUnavailable,
}

class ReviewCorpusIdentityMap {
  final Set<String> activeWordIds;
  final Set<String> activeSentenceIds;
  final Map<String, ReviewIdAlias> aliases;
  final Map<String, ReviewIdTombstone> tombstones;
  final bool isDegraded;

  ReviewCorpusIdentityMap({
    required Set<String> activeWordIds,
    required Set<String> activeSentenceIds,
    required List<ReviewIdAlias> aliases,
    required List<ReviewIdTombstone> tombstones,
    this.isDegraded = false,
  }) : activeWordIds = Set.unmodifiable(activeWordIds),
       activeSentenceIds = Set.unmodifiable(activeSentenceIds),
       aliases = Map.unmodifiable({for (final a in aliases) a.from: a}),
       tombstones = Map.unmodifiable({for (final t in tombstones) t.id: t});

  factory ReviewCorpusIdentityMap.empty() => ReviewCorpusIdentityMap(
    activeWordIds: const {},
    activeSentenceIds: const {},
    aliases: const [],
    tombstones: const [],
  );

  factory ReviewCorpusIdentityMap.degraded({
    Set<String> activeWordIds = const {},
    Set<String> activeSentenceIds = const {},
  }) => ReviewCorpusIdentityMap(
    activeWordIds: activeWordIds,
    activeSentenceIds: activeSentenceIds,
    aliases: const [],
    tombstones: const [],
    isDegraded: true,
  );

  CorpusAvailabilityState get availabilityState {
    final hasCorpus = activeWordIds.isNotEmpty || activeSentenceIds.isNotEmpty;
    if (!hasCorpus) return CorpusAvailabilityState.corpusUnavailable;
    if (isDegraded) {
      return CorpusAvailabilityState.corpusAvailableManifestUnavailable;
    }
    return CorpusAvailabilityState.ready;
  }

  bool isActive(String itemId) =>
      activeWordIds.contains(itemId) || activeSentenceIds.contains(itemId);

  bool isWord(String itemId) => activeWordIds.contains(itemId);

  bool isSentence(String itemId) => activeSentenceIds.contains(itemId);

  bool isTombstoned(String itemId) => tombstones.containsKey(itemId);

  ReviewIdAlias? aliasFor(String itemId) => aliases[itemId];

  /// Resolves an alias chain to its canonical target.
  ///
  /// Returns null if not aliased, or if a cycle is detected, or if the
  /// target is missing from the active corpus, or if the item type mismatches.
  String? resolveCanonicalId(String itemId, {ReviewItemType? expectedType}) {
    if (!aliases.containsKey(itemId)) return null;

    final visited = <String>{itemId};
    var curr = itemId;

    while (aliases.containsKey(curr)) {
      final alias = aliases[curr]!;
      if (expectedType != null && alias.itemType != expectedType) {
        return null;
      }
      final next = alias.to;
      if (visited.contains(next)) {
        AppLogger.warning(
          'ReviewCorpusIdentityMap: alias cycle detected for "$itemId" -> "$next"',
        );
        return null;
      }
      visited.add(next);
      curr = next;
    }

    if (!isActive(curr)) {
      AppLogger.warning(
        'ReviewCorpusIdentityMap: final alias target "$curr" for "$itemId" is not in active corpus',
      );
      return null;
    }

    if (expectedType != null) {
      final targetIsWord = isWord(curr);
      if (expectedType == ReviewItemType.word && !targetIsWord) {
        return null;
      }
      if (expectedType == ReviewItemType.sentence && targetIsWord) {
        return null;
      }
    }

    return curr;
  }

  /// Parses catalogs and manifest from JSON strings (unit-test friendly).
  factory ReviewCorpusIdentityMap.fromStringCatalogs({
    required String wordsJson,
    required String sentencesJson,
    required String manifestJson,
  }) {
    var isDegraded = false;
    final wordIds = <String>{};
    try {
      final wordsList = jsonDecode(wordsJson);
      if (wordsList is List) {
        for (final w in wordsList) {
          if (w is Map &&
              w['id'] is String &&
              (w['id'] as String).trim().isNotEmpty) {
            wordIds.add((w['id'] as String).trim());
          }
        }
      } else {
        isDegraded = true;
      }
    } catch (e) {
      isDegraded = true;
      AppLogger.error('ReviewCorpusIdentityMap: malformed wordsJson: $e');
    }

    final sentenceIds = <String>{};
    try {
      final sentencesList = jsonDecode(sentencesJson);
      if (sentencesList is List) {
        for (final s in sentencesList) {
          if (s is Map &&
              s['id'] is String &&
              (s['id'] as String).trim().isNotEmpty) {
            sentenceIds.add((s['id'] as String).trim());
          }
        }
      } else {
        isDegraded = true;
      }
    } catch (e) {
      isDegraded = true;
      AppLogger.error('ReviewCorpusIdentityMap: malformed sentencesJson: $e');
    }

    ReviewIdMigrationManifest manifest = ReviewIdMigrationManifest.empty;
    try {
      final manifestDecoded = jsonDecode(manifestJson);
      if (manifestDecoded is Map<String, dynamic>) {
        manifest = ReviewIdMigrationManifest.fromJson(manifestDecoded);
      } else if (manifestDecoded is Map) {
        manifest = ReviewIdMigrationManifest.fromJson(
          Map<String, dynamic>.from(manifestDecoded),
        );
      } else {
        manifest = ReviewIdMigrationManifest.degraded;
      }
    } catch (e) {
      manifest = ReviewIdMigrationManifest.degraded;
      AppLogger.error('ReviewCorpusIdentityMap: malformed manifestJson: $e');
    }

    if (manifest.isDegraded) {
      isDegraded = true;
    }

    // Check for alias cycles in manifest
    if (!isDegraded) {
      final aliasMap = {for (final a in manifest.aliases) a.from: a.to};
      for (final start in aliasMap.keys) {
        final visited = <String>{start};
        var curr = start;
        while (aliasMap.containsKey(curr)) {
          final next = aliasMap[curr]!;
          if (visited.contains(next)) {
            AppLogger.error(
              'ReviewCorpusIdentityMap: invalid alias cycle detected in manifest: "$start" -> "$next"',
            );
            isDegraded = true;
            break;
          }
          visited.add(next);
          curr = next;
        }
        if (isDegraded) break;
      }
    }

    return ReviewCorpusIdentityMap(
      activeWordIds: wordIds,
      activeSentenceIds: sentenceIds,
      aliases: isDegraded ? const [] : manifest.aliases,
      tombstones: isDegraded ? const [] : manifest.tombstones,
      isDegraded: isDegraded,
    );
  }

  /// Loads bundled seed catalogs from assets. Safe fallback to degraded map.
  static Future<ReviewCorpusIdentityMap> loadBundled() async {
    String wordsRaw = '[]';
    String sentencesRaw = '[]';
    String manifestRaw = '{"schemaVersion":1,"aliases":[],"tombstones":[]}';
    var isDegraded = false;

    try {
      wordsRaw = await rootBundle.loadString('assets/seed/words.json');
    } catch (e) {
      isDegraded = true;
      AppLogger.error(
        'ReviewCorpusIdentityMap: failed to load assets/seed/words.json: $e',
      );
    }

    try {
      sentencesRaw = await rootBundle.loadString('assets/seed/sentences.json');
    } catch (e) {
      isDegraded = true;
      AppLogger.error(
        'ReviewCorpusIdentityMap: failed to load assets/seed/sentences.json: $e',
      );
    }

    try {
      manifestRaw = await rootBundle.loadString(
        'assets/seed/review_item_id_migrations.json',
      );
    } catch (e) {
      isDegraded = true;
      AppLogger.error(
        'ReviewCorpusIdentityMap: failed to load assets/seed/review_item_id_migrations.json: $e',
      );
    }

    final parsed = ReviewCorpusIdentityMap.fromStringCatalogs(
      wordsJson: wordsRaw,
      sentencesJson: sentencesRaw,
      manifestJson: manifestRaw,
    );

    if (isDegraded || parsed.isDegraded) {
      return ReviewCorpusIdentityMap.degraded(
        activeWordIds: parsed.activeWordIds,
        activeSentenceIds: parsed.activeSentenceIds,
      );
    }
    return parsed;
  }
}

class ReviewReconciliationResult {
  final Map<String, MemoryItemState> activeStates;
  final Map<String, MemoryItemState> quarantinedStates;
  final List<String> renamedOldIds;
  final List<String> tombstonedIds;
  final int collisionsResolved;
  final bool hasChanges;

  const ReviewReconciliationResult({
    required this.activeStates,
    required this.quarantinedStates,
    required this.renamedOldIds,
    required this.tombstonedIds,
    required this.collisionsResolved,
    required this.hasChanges,
  });

  int get activeCount => activeStates.length;
  int get orphanCount => quarantinedStates.length;
  int get tombstoneCount => tombstonedIds.length;
  int get renameCount => renamedOldIds.length;
}

class ReviewStateReconciler {
  const ReviewStateReconciler._();

  /// Deterministically reconciles stored states against the verified corpus.
  ///
  /// Classifications:
  /// 1. Active: ID exists in active corpus -> keep as is.
  /// 2. Renamed: explicit alias -> rename to canonical ID preserving all scheduler fields.
  ///    Collision resolution uses effective timestamp: lastReviewedAt ?? introducedAt.
  ///    Newer wins; if tied, canonical already stored wins. No fields or counters merged.
  /// 3. Tombstoned: explicit deletion -> remove from active learning, track for cloud cleanup.
  /// 4. Unknown orphan: not active, aliased, or tombstoned -> quarantine, log, do not delete.
  static ReviewReconciliationResult reconcile({
    required Map<String, MemoryItemState> states,
    required ReviewCorpusIdentityMap corpusMap,
    Map<String, MemoryItemState>? existingQuarantine,
  }) {
    // If corpus map is not ready (manifest unavailable or corpus unavailable),
    // fail safely without dropping or destructively modifying states.
    final availability = corpusMap.availabilityState;
    if (availability != CorpusAvailabilityState.ready) {
      AppLogger.warning(
        'ReviewStateReconciler: degraded mode ($availability) - skipping destructive reconciliation. '
        'Preserving ${states.length} stored states without persisting new quarantine decisions.',
      );
      return ReviewReconciliationResult(
        activeStates: Map.of(states),
        quarantinedStates: Map.of(existingQuarantine ?? const {}),
        renamedOldIds: const [],
        tombstonedIds: const [],
        collisionsResolved: 0,
        hasChanges: false,
      );
    }

    final active = <String, MemoryItemState>{};
    final quarantined = Map<String, MemoryItemState>.of(
      existingQuarantine ?? const {},
    );
    final renamedOldIds = <String>[];
    final tombstonedIds = <String>[];
    var collisionsResolved = 0;
    var hasChanges = false;

    // First pass: populate directly active items
    for (final entry in states.entries) {
      final item = entry.value;
      if (corpusMap.isActive(item.itemId)) {
        active[item.itemId] = item;
      }
    }

    // Second pass: handle aliases, tombstones, and unknown orphans
    for (final entry in states.entries) {
      final oldId = entry.key;
      final state = entry.value;

      if (corpusMap.isActive(oldId)) {
        // Handled in first pass
        continue;
      }

      // Explicit tombstone
      if (corpusMap.isTombstoned(oldId)) {
        hasChanges = true;
        tombstonedIds.add(oldId);
        continue;
      }

      // Explicit alias
      final canonicalId = corpusMap.resolveCanonicalId(
        oldId,
        expectedType: state.itemType,
      );

      if (canonicalId != null) {
        hasChanges = true;
        renamedOldIds.add(oldId);

        final renamedState = state.copyWith(itemId: canonicalId);
        final existingCanonical = active[canonicalId];

        if (existingCanonical == null) {
          active[canonicalId] = renamedState;
        } else {
          // Collision resolution: whole-state winner based on effective timestamp
          collisionsResolved++;
          final oldTs =
              renamedState.lastReviewedAt ?? renamedState.introducedAt;
          final canonicalTs =
              existingCanonical.lastReviewedAt ??
              existingCanonical.introducedAt;

          if (oldTs.isAfter(canonicalTs)) {
            active[canonicalId] = renamedState;
            AppLogger.debug(
              'ReviewStateReconciler: collision on "$canonicalId" resolved: '
              'aliased state "$oldId" won (newer effective timestamp $oldTs vs $canonicalTs)',
            );
          } else {
            // Existing canonical wins on newer or equal timestamp
            AppLogger.debug(
              'ReviewStateReconciler: collision on "$canonicalId" resolved: '
              'existing canonical state won ($canonicalTs >= $oldTs)',
            );
          }
        }
        continue;
      }

      // Unknown orphan: quarantine and preserve
      hasChanges = true;
      quarantined[oldId] = state;
      AppLogger.warning(
        'ReviewStateReconciler: unknown orphan state quarantined: itemId="$oldId", '
        'type=${state.itemType}, mastery=${state.masteryState}',
      );
    }

    return ReviewReconciliationResult(
      activeStates: active,
      quarantinedStates: quarantined,
      renamedOldIds: renamedOldIds,
      tombstonedIds: tombstonedIds,
      collisionsResolved: collisionsResolved,
      hasChanges: hasChanges,
    );
  }
}
