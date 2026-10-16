import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AdConfig {
  const AdConfig._();

  // Test Ad Unit IDs provided by Google AdMob
  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String testAndroidNativeId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String testIosNativeId =
      'ca-app-pub-3940256099942544/3986624511';

  static const String testAndroidAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String testIosAppOpenId =
      'ca-app-pub-3940256099942544/5575463023';

  // Production Ad Unit IDs generated from Google AdMob for Olitun (com.ol.itun)
  static const String prodAndroidAppId =
      'ca-app-pub-7288061764998409~8819895924';
  static const String prodAndroidBannerId =
      'ca-app-pub-7288061764998409/4259045833';
  static const String prodAndroidInterstitialId =
      'ca-app-pub-7288061764998409/2945964166';
  static const String prodAndroidRewardedId =
      'ca-app-pub-7288061764998409/6393043138';
  static const String prodAndroidNativeId =
      'ca-app-pub-7288061764998409/6987939502';

  /// No production App Open unit exists yet. Create one in AdMob and set it
  /// via the admin `admob_app_open_id` setting; until then app open ads stay
  /// off in release builds.
  static const String prodAndroidAppOpenId = '';

  // Unit IDs pushed from the `app_settings` collection (admin AdMob section).
  // A non-empty remote value wins over the bundled production ID, so units can
  // be swapped without shipping a release. Compile-time defines still win.
  static final Map<String, String> _remoteUnitIds = {};

  /// Apply remote unit ID overrides. Empty values clear the override.
  static void applyRemoteUnitIds(Map<String, String> ids) {
    for (final entry in ids.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) {
        _remoteUnitIds.remove(entry.key);
      } else {
        _remoteUnitIds[entry.key] = value;
      }
    }
  }

  @visibleForTesting
  static void clearRemoteUnitIds() => _remoteUnitIds.clear();

  static String? _remote(String key) => isTestMode ? null : _remoteUnitIds[key];

  /// Whether AdMob is currently running in test mode.
  static bool get isTestMode {
    const definedTestMode = String.fromEnvironment('ADMOB_TEST_MODE');
    if (definedTestMode.isNotEmpty) {
      return definedTestMode.toLowerCase() == 'true';
    }
    return !kReleaseMode;
  }

  /// App ID based on platform & environment.
  static String get adMobAppId {
    const definedAppId = String.fromEnvironment('ADMOB_APP_ID');
    if (definedAppId.isNotEmpty) return definedAppId;

    if (kIsWeb) return '';
    if (!isTestMode) {
      if (Platform.isIOS) return testIosAppId;
      return prodAndroidAppId;
    }
    if (Platform.isIOS) {
      return testIosAppId;
    }
    return testAndroidAppId;
  }

  /// Banner Ad Unit ID.
  static String get bannerAdUnitId {
    const defined = String.fromEnvironment('ADMOB_BANNER_ID');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return '';
    final remote = _remote('banner');
    if (remote != null) return remote;
    if (!isTestMode) {
      if (Platform.isIOS) return testIosBannerId;
      return prodAndroidBannerId;
    }
    if (Platform.isIOS) {
      return testIosBannerId;
    }
    return testAndroidBannerId;
  }

  /// Interstitial Ad Unit ID.
  static String get interstitialAdUnitId {
    const defined = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return '';
    final remote = _remote('interstitial');
    if (remote != null) return remote;
    if (!isTestMode) {
      if (Platform.isIOS) return testIosInterstitialId;
      return prodAndroidInterstitialId;
    }
    if (Platform.isIOS) {
      return testIosInterstitialId;
    }
    return testAndroidInterstitialId;
  }

  /// Rewarded Ad Unit ID.
  static String get rewardedAdUnitId {
    const defined = String.fromEnvironment('ADMOB_REWARDED_ID');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return '';
    final remote = _remote('rewarded');
    if (remote != null) return remote;
    if (!isTestMode) {
      if (Platform.isIOS) return testIosRewardedId;
      return prodAndroidRewardedId;
    }
    if (Platform.isIOS) {
      return testIosRewardedId;
    }
    return testAndroidRewardedId;
  }

  /// Native Ad Unit ID.
  static String get nativeAdUnitId {
    const defined = String.fromEnvironment('ADMOB_NATIVE_ID');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return '';
    final remote = _remote('native');
    if (remote != null) return remote;
    if (!isTestMode) {
      if (Platform.isIOS) return testIosNativeId;
      return prodAndroidNativeId;
    }
    if (Platform.isIOS) {
      return testIosNativeId;
    }
    return testAndroidNativeId;
  }

  /// App Open Ad Unit ID. Empty disables app open ads.
  static String get appOpenAdUnitId {
    const defined = String.fromEnvironment('ADMOB_APP_OPEN_ID');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return '';
    final remote = _remote('app_open');
    if (remote != null) return remote;
    if (!isTestMode) {
      if (Platform.isIOS) return testIosAppOpenId;
      return prodAndroidAppOpenId;
    }
    if (Platform.isIOS) {
      return testIosAppOpenId;
    }
    return testAndroidAppOpenId;
  }

  /// Universal test fallback ad unit IDs (guaranteed fill from Google sample units).
  /// Strictly restricted to test/debug mode so end users in production release
  /// never receive test ads or native ad validator overlays.
  static String get fallbackBannerAdUnitId {
    if (kIsWeb || !isTestMode) return '';
    return Platform.isIOS ? testIosBannerId : testAndroidBannerId;
  }

  static String get fallbackInterstitialAdUnitId {
    if (kIsWeb || !isTestMode) return '';
    return Platform.isIOS ? testIosInterstitialId : testAndroidInterstitialId;
  }

  static String get fallbackRewardedAdUnitId {
    if (kIsWeb || !isTestMode) return '';
    return Platform.isIOS ? testIosRewardedId : testAndroidRewardedId;
  }

  static String get fallbackNativeAdUnitId {
    if (kIsWeb || !isTestMode) return '';
    return Platform.isIOS ? testIosNativeId : testAndroidNativeId;
  }

  /// Test Device IDs for physical device verification.
  static List<String> get testDeviceIds {
    const definedDevices = String.fromEnvironment('ADMOB_TEST_DEVICES');
    if (definedDevices.isNotEmpty) {
      return definedDevices
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Default interstitial frequency cap in minutes.
  static const int defaultInterstitialIntervalMinutes = 2;

  /// Default minimum gap between app open ads, in minutes.
  static const int defaultAppOpenIntervalMinutes = 120;

  /// Minimum time in the background before a resume may show an app open ad.
  static const Duration appOpenMinBackground = Duration(seconds: 30);

  /// Loaded full-screen ads expire on Google's side; drop them before then.
  static const Duration fullScreenAdTtl = Duration(minutes: 55);
  static const Duration appOpenAdTtl = Duration(hours: 4);

  /// After this many consecutive no-fills, a format pauses requests for
  /// [noFillPause] so empty retries don't drag the match rate down.
  static const int noFillStreakLimit = 3;
  static const Duration noFillPause = Duration(seconds: 90);

  /// Default rewarded ad cooldown in minutes.
  static const int defaultRewardedCooldownMinutes = 10;
}
