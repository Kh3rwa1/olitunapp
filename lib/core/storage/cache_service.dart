import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class CacheService {
  static const String _boxName = 'content_cache';

  /// Save data to cache
  static Future<void> set(String key, dynamic data) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = jsonEncode(data);
      await box.put(key, jsonString);
      debugPrint('📦 [Cache] Saved: $key');
    } catch (e) {
      debugPrint('⚠️ [Cache] Write Error ($key): $e');
    }
  }

  /// Get data from cache
  static Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = box.get(key);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString);
        debugPrint('📦 [Cache] Hit: $key');
        return fromJson(decoded as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('⚠️ [Cache] Read Error ($key): $e');
    }
    return null;
  }

  /// Get a list of data from cache
  static Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = box.get(key);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List;
        debugPrint('📦 [Cache] Hit: $key');
        return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [Cache] Read List Error ($key): $e');
    }
    return null;
  }

  /// Clear a specific key
  static Future<void> delete(String key) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(key);
  }

  /// Clear all cache
  static Future<void> clear() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
