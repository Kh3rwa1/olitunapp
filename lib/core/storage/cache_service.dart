import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Schema version for cache invalidation across app updates.
/// Bump this when the serialisation format of cached models changes.
const int cacheSchemaVersion = 2;

/// Envelope that wraps every cached value with TTL and schema metadata.
class CacheEntry {
  final dynamic data;
  final int schemaVersion;
  final int createdAtMs;
  final int? ttlMs;

  CacheEntry({
    required this.data,
    required this.schemaVersion,
    required this.createdAtMs,
    this.ttlMs,
  });

  bool get isExpired {
    if (ttlMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch - createdAtMs > ttlMs!;
  }

  bool get isSchemaMismatch => schemaVersion != cacheSchemaVersion;

  Map<String, dynamic> toJson() => {
    '_v': schemaVersion,
    '_ts': createdAtMs,
    if (ttlMs != null) '_ttl': ttlMs,
    'd': data,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    schemaVersion: json['_v'] as int? ?? 0,
    createdAtMs: json['_ts'] as int? ?? 0,
    ttlMs: json['_ttl'] as int?,
    data: json['d'],
  );
}

/// Lightweight Hive-backed JSON cache used by content providers.
///
/// Every entry is stored with [CacheEntry] metadata: schema version,
/// creation timestamp, and an optional TTL. Reads automatically discard
/// stale or schema-mismatched entries.
class CacheService {
  static const String _boxName = 'content_cache';

  /// Default TTL: 24 hours.
  static const Duration defaultTtl = Duration(hours: 24);

  /// Lazily-opened, long-lived box handle.
  static Box? _box;

  @visibleForTesting
  static void resetForTesting() => _box = null;

  static Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  /// Write [data] under [key] with optional [ttl] (defaults to 24 h).
  static Future<void> set(String key, dynamic data, {Duration? ttl}) async {
    try {
      final box = await _getBox();
      final entry = CacheEntry(
        data: data,
        schemaVersion: cacheSchemaVersion,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ttlMs: (ttl ?? defaultTtl).inMilliseconds,
      );
      await box.put(key, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('[Cache] write error ($key): $e');
      rethrow;
    }
  }

  /// Read a cached object. Returns `null` when the entry is missing,
  /// expired, or was written under a different schema version.
  static Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;

      final envelope = _unwrap(raw as String);
      if (envelope == null) return null;

      final innerData = envelope.data;
      if (innerData is Map<String, dynamic>) {
        return fromJson(innerData);
      }
      return null;
    } catch (e) {
      debugPrint('[Cache] read error ($key): $e');
      return null;
    }
  }

  static Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;

      final envelope = _unwrap(raw as String);
      if (envelope == null) return null;

      final list = envelope.data as List;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      debugPrint('[Cache] read list error ($key): $e');
      return null;
    }
  }

  /// Returns metadata about an entry without deserialising the payload.
  static Future<CacheEntry?> getMeta(String key) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;
      return _unwrap(raw as String, skipValidation: true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String key) async {
    final box = await _getBox();
    await box.delete(key);
  }

  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Evict all entries whose TTL has expired or whose schema is stale.
  static Future<int> evictStale() async {
    final box = await _getBox();
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      try {
        final raw = box.get(key);
        if (raw == null) continue;
        final entry = CacheEntry.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>,
        );
        if (entry.isExpired || entry.isSchemaMismatch) {
          keysToDelete.add(key);
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }
    await box.deleteAll(keysToDelete);
    debugPrint('[Cache] evictStale: removed ${keysToDelete.length} entries');
    return keysToDelete.length;
  }

  // ── Internal ──────────────────────────────────────────

  /// Parse a raw JSON string into a [CacheEntry], returning null if
  /// the entry is expired or schema-mismatched.
  static CacheEntry? _unwrap(String raw, {bool skipValidation = false}) {
    final json = jsonDecode(raw);

    // Backwards compatibility: if it's not an envelope, skip.
    if (json is! Map<String, dynamic> || !json.containsKey('_v')) {
      return null;
    }

    final entry = CacheEntry.fromJson(json);
    if (!skipValidation && (entry.isExpired || entry.isSchemaMismatch)) {
      return null;
    }
    return entry;
  }
}
