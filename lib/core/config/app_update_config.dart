import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/hive_service.dart';
import 'app_settings_provider.dart';

/// Minimum-build policy. The admin sets `min_supported_build` (Android
/// versionCode, YYMMDDHH) in app_settings when an old build can no longer
/// work (for example after the Appwrite sign-in outage); every older build
/// then shows the update screen instead of a broken app. `latest_build` only
/// drives a dismissible "update available" hint.
class AppUpdatePolicy {
  const AppUpdatePolicy._();

  static const minSupportedBuildKey = 'min_supported_build';
  static const latestBuildKey = 'latest_build';

  /// Last minimum the device saw, so an offline cold start still honours it.
  static const cachedMinSupportedBuildKey =
      'app_update_cached_min_supported_build';

  static const playPackageId = 'com.ol.itun';
  static final Uri playMarketUri = Uri.parse(
    'market://details?id=$playPackageId',
  );
  static final Uri playWebUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$playPackageId',
  );

  /// Parses an admin-entered build number; anything that is not a positive
  /// integer counts as "not set" so a typo can never lock everyone out.
  static int? parseBuild(Object? raw) {
    final int? value;
    if (raw is int) {
      value = raw;
    } else if (raw is num) {
      value = raw.isFinite ? raw.toInt() : null;
    } else if (raw is String) {
      value = int.tryParse(raw.trim());
    } else {
      value = null;
    }
    if (value == null || value <= 0) return null;
    return value;
  }

  static bool requiresUpdate({
    required int? current,
    required int? minSupported,
  }) {
    if (current == null || minSupported == null) return false;
    return current < minSupported;
  }

  static bool hasNewerBuild({required int? current, required int? latest}) {
    if (current == null || latest == null) return false;
    return current < latest;
  }
}

/// The running build's Android versionCode. Null on web and when the
/// platform channel is unavailable (then no gate can apply).
final currentBuildNumberProvider = FutureProvider<int?>((ref) async {
  if (kIsWeb) return null;
  try {
    final info = await PackageInfo.fromPlatform();
    return AppUpdatePolicy.parseBuild(info.buildNumber);
  } catch (_) {
    return null;
  }
});

SharedPreferences? _prefsOrNull(Ref ref) {
  try {
    return ref.read(sharedPreferencesProvider);
  } catch (_) {
    return null;
  }
}

/// `min_supported_build` from remote settings, falling back to the cached
/// value while settings are loading or unavailable. A loaded settings map
/// without the key clears the cache (the admin lifted the gate).
final minSupportedBuildProvider = Provider<int?>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  final prefs = _prefsOrNull(ref);
  final cached = AppUpdatePolicy.parseBuild(
    prefs?.getInt(AppUpdatePolicy.cachedMinSupportedBuildKey),
  );
  // appSettingsProvider yields an empty map both when nothing is configured
  // and when the request failed, so an empty map keeps the cached value.
  if (settings == null || settings.isEmpty) return cached;

  final remote = AppUpdatePolicy.parseBuild(
    settings[AppUpdatePolicy.minSupportedBuildKey],
  );
  if (prefs != null && remote != cached) {
    unawaited(
      (remote == null
              ? prefs.remove(AppUpdatePolicy.cachedMinSupportedBuildKey)
              : prefs.setInt(
                  AppUpdatePolicy.cachedMinSupportedBuildKey,
                  remote,
                ))
          .catchError((_) => false),
    );
  }
  return remote;
});

/// `latest_build` from remote settings (no cache: a hint, not a gate).
final latestBuildProvider = Provider<int?>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  if (settings == null) return null;
  return AppUpdatePolicy.parseBuild(settings[AppUpdatePolicy.latestBuildKey]);
});

/// True when this build is older than the minimum the admin still supports.
/// Never true on web, and never true while the build number is unknown.
final updateRequiredProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  final current = ref.watch(currentBuildNumberProvider).valueOrNull;
  return AppUpdatePolicy.requiresUpdate(
    current: current,
    minSupported: ref.watch(minSupportedBuildProvider),
  );
});

/// True when a newer build is published than the one running.
final updateAvailableProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  final current = ref.watch(currentBuildNumberProvider).valueOrNull;
  return AppUpdatePolicy.hasNewerBuild(
    current: current,
    latest: ref.watch(latestBuildProvider),
  );
});
