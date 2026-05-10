import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_service.dart';

/// Riverpod provider for [SharedPreferences].
///
/// Override this at the root `ProviderScope` with the instance created during
/// [initStorage]. All code should read from this provider instead of using a
/// mutable top-level variable.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw StateError(
    'sharedPreferencesProvider must be overridden with a concrete '
    'SharedPreferences instance at the root ProviderScope.',
  );
});

/// Centralized storage initialization.
///
/// Returns the [SharedPreferences] instance so the caller can feed it into
/// the `ProviderScope` override.
/// Also evicts stale cache entries on every startup.
Future<SharedPreferences> initStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  // Evict expired / schema-mismatched cache entries on startup.
  await CacheService.evictStale();
  return prefs;
}
