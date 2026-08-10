import 'package:itun/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Schema version for cache invalidation across app updates.
/// Bump this when the serialisation format of cached models changes.
const int cacheSchemaVersion = 4;

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

  /// Active future for opening the box to prevent concurrent open race conditions.
  static Future<Box>? _openBoxFuture;

  static bool get isOpen => _box != null && _box!.isOpen;

  @visibleForTesting
  static void resetForTesting() {
    _box = null;
    _openBoxFuture = null;
  }

  static Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (_openBoxFuture != null) return _openBoxFuture!;

    _openBoxFuture = () async {
      try {
        final box = await Hive.openBox(_boxName);
        _box = box;
        return box;
      } catch (e) {
        AppLogger.debug('[Cache] Failed to open Hive box: $e');
        _box = null;
        rethrow;
      } finally {
        _openBoxFuture = null;
      }
    }();

    return _openBoxFuture!;
  }

  /// Reset the box handle if a connection or invalid state error is detected,
  /// so that subsequent calls attempt a fresh open.
  static void _handleCacheError(Object error) {
    AppLogger.debug('[Cache] Database error occurred: $error');
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('closing') ||
        errStr.contains('invalidstateerror') ||
        errStr.contains('databaseclosed') ||
        errStr.contains('closed')) {
      try {
        if (_box != null) {
          _box!.close();
        }
      } catch (_) {}
      _box = null;
    }
  }

  /// Write [data] under [key] with optional [ttl] (defaults to 24 h).
  static Future<bool> set(String key, dynamic data, {Duration? ttl}) async {
    try {
      final box = await _getBox();
      final entry = CacheEntry(
        data: data,
        schemaVersion: cacheSchemaVersion,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ttlMs: (ttl ?? defaultTtl).inMilliseconds,
      );
      await box.put(key, jsonEncode(entry.toJson()));
      return true;
    } catch (e) {
      AppLogger.debug('[Cache] write error ($key): $e');
      _handleCacheError(e);
      return false;
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
      AppLogger.debug('[Cache] read error ($key): $e');
      _handleCacheError(e);
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
      AppLogger.debug('[Cache] read list error ($key): $e');
      _handleCacheError(e);
      return null;
    }
  }

  /// Read a cached object even if expired (ignoring TTL), returning `null`
  /// only when the entry is missing or written under a mismatched schema version.
  static Future<T?> getIgnoringTtl<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;

      final envelope = _unwrap(raw as String, ignoreTtl: true);
      if (envelope == null) return null;

      final innerData = envelope.data;
      if (innerData is Map<String, dynamic>) {
        return fromJson(innerData);
      }
      return null;
    } catch (e) {
      AppLogger.debug('[Cache] read ignoring TTL error ($key): $e');
      _handleCacheError(e);
      return null;
    }
  }

  /// Returns metadata about an entry without deserialising the payload.
  static Future<CacheEntry?> getMeta(String key) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;
      return _unwrap(raw as String, ignoreTtl: true);
    } catch (e) {
      _handleCacheError(e);
      return null;
    }
  }

  static Future<bool> delete(String key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
      return true;
    } catch (e) {
      AppLogger.debug('[Cache] delete error ($key): $e');
      _handleCacheError(e);
      return false;
    }
  }

  static Future<bool> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
      return true;
    } catch (e) {
      AppLogger.debug('[Cache] clear error: $e');
      _handleCacheError(e);
      return false;
    }
  }

  /// Evict all entries whose TTL has expired or whose schema is stale.
  static Future<int> evictStale() async {
    try {
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
      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
      }
      AppLogger.debug(
        '[Cache] evictStale: removed ${keysToDelete.length} entries',
      );
      return keysToDelete.length;
    } catch (e) {
      AppLogger.debug('[Cache] evictStale error: $e');
      _handleCacheError(e);
      return 0;
    }
  }

  // ── Internal ──────────────────────────────────────────

  /// Parse a raw JSON string into a [CacheEntry], returning null if
  /// schema-mismatched or (unless [ignoreTtl] is true) expired.
  static CacheEntry? _unwrap(String raw, {bool ignoreTtl = false}) {
    final json = jsonDecode(raw);

    // Backwards compatibility: if it's not an envelope, skip.
    if (json is! Map<String, dynamic> || !json.containsKey('_v')) {
      return null;
    }

    final entry = CacheEntry.fromJson(json);
    if (entry.isSchemaMismatch) {
      return null;
    }
    if (!ignoreTtl && entry.isExpired) {
      return null;
    }
    return entry;
  }
}
