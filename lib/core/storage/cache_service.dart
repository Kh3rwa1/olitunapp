import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Lightweight Hive-backed JSON cache used by content providers.
///
/// The box is opened once (lazily, on first access) and reused for the
/// lifetime of the app. This avoids the overhead of calling
/// `Hive.openBox` on every read/write.
class CacheService {
  static const String _boxName = 'content_cache';

  /// Lazily-opened, long-lived box handle.
  static Box? _box;

  @visibleForTesting
  static void resetForTesting() => _box = null;

  static Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  static Future<void> set(String key, dynamic data) async {
    try {
      final box = await _getBox();
      await box.put(key, jsonEncode(data));
    } catch (e) {
      debugPrint('[Cache] write error ($key): $e');
    }
  }

  static Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await _getBox();
      final raw = box.get(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
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
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      debugPrint('[Cache] read list error ($key): $e');
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
}
