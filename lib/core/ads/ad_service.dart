import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../config/ad_config.dart';
import '../logging/app_logger.dart';
import 'ad_error.dart';
import 'consent_manager.dart';
import 'native_ad_factory.dart';

class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  ConsentManager? _consentManager;
  ConsentManager get consentManager => _consentManager ??= ConsentManager();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get canServeAds => _isInitialized && consentManager.requestsAllowed;

  DateTime? _lastBackgroundedAt;

  final Set<Ad> _activeAds = {};

  /// Initialize MobileAds SDK and configuration safely.
  Future<Either<AdError, bool>> initialize({
    ConsentManager? consentManager,
  }) async {
    if (kIsWeb) {
      _isInitialized = true;
      return right<AdError, bool>(true);
    }

    if (_isInitialized) {
      return right<AdError, bool>(true);
    }

    if (consentManager != null) {
      _consentManager = consentManager;
    }

    try {
      WidgetsBinding.instance.addObserver(this);

      // Configure test devices
      if (AdConfig.testDeviceIds.isNotEmpty) {
        final config = RequestConfiguration(
          testDeviceIds: AdConfig.testDeviceIds,
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        );
        await MobileAds.instance.updateRequestConfiguration(config);
      }

      // Request UMP consent update
      await this.consentManager.requestConsentInfo();

      // Initialize MobileAds instance
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;
      AppLogger.debug(
        'AdService: MobileAds initialized: ${status.adapterStatuses}',
      );

      // Register default native ad factory
      registerOlitunNativeAdFactory();

      return right<AdError, bool>(true);
    } catch (e, stack) {
      AppLogger.debug('AdService: Initialization error: $e\n$stack');
      return left<AdError, bool>(AdInitError('Failed to initialize AdMob: $e'));
    }
  }

  /// Show consent form if required by GDPR/UMP rules.
  Future<Either<AdError, ConsentStatus>> showConsentFormIfNeeded(
    BuildContext context,
  ) async {
    if (kIsWeb) return right<AdError, ConsentStatus>(ConsentStatus.notRequired);
    return consentManager.showConsentFormIfRequired();
  }

  /// Helper to create and load a responsive BannerAd.
  BannerAd? createBannerAd({
    required AdSize size,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
    void Function(Ad)? onOpened,
    void Function(Ad)? onClosed,
    void Function(Ad)? onImpression,
    void Function(Ad)? onClicked,
  }) {
    if (kIsWeb || !canServeAds) return null;

    final unitId = AdConfig.bannerAdUnitId;
    if (unitId.isEmpty) return null;

    BannerAd? banner;
    banner = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _activeAds.add(ad);
          onLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          _activeAds.remove(ad);
          ad.dispose();
          onFailed(ad, error);
        },
        onAdOpened: onOpened,
        onAdClosed: onClosed,
        onAdImpression: onImpression,
        onAdClicked: onClicked,
      ),
    );

    banner.load();
    return banner;
  }

  /// Load Interstitial Ad.
  Future<Either<AdError, InterstitialAd>> loadInterstitialAd() async {
    if (kIsWeb) {
      return left<AdError, InterstitialAd>(const AdPlatformUnsupportedError());
    }

    if (!canServeAds) {
      return left<AdError, InterstitialAd>(
        AdConsentError('Ad consent is not available.', 'consent_unavailable'),
      );
    }

    final unitId = AdConfig.interstitialAdUnitId;
    if (unitId.isEmpty) {
      return left<AdError, InterstitialAd>(
        const AdInitError('Interstitial ad unit ID is empty'),
      );
    }

    final completer = Completer<Either<AdError, InterstitialAd>>();

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _activeAds.add(ad);
          completer.complete(right<AdError, InterstitialAd>(ad));
        },
        onAdFailedToLoad: (error) {
          completer.complete(
            left<AdError, InterstitialAd>(
              AdLoadError(error.message, error.code.toString()),
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  /// Load Rewarded Ad.
  Future<Either<AdError, RewardedAd>> loadRewardedAd() async {
    if (kIsWeb) {
      return left<AdError, RewardedAd>(const AdPlatformUnsupportedError());
    }

    if (!canServeAds) {
      return left<AdError, RewardedAd>(
        AdConsentError('Ad consent is not available.', 'consent_unavailable'),
      );
    }

    final unitId = AdConfig.rewardedAdUnitId;
    if (unitId.isEmpty) {
      return left<AdError, RewardedAd>(
        const AdInitError('Rewarded ad unit ID is empty'),
      );
    }

    final completer = Completer<Either<AdError, RewardedAd>>();

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _activeAds.add(ad);
          completer.complete(right<AdError, RewardedAd>(ad));
        },
        onAdFailedToLoad: (error) {
          completer.complete(
            left<AdError, RewardedAd>(
              AdLoadError(error.message, error.code.toString()),
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  /// Load Native Ad.
  NativeAd? createNativeAd({
    String? factoryId,
    NativeTemplateStyle? nativeTemplateStyle,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
    void Function(Ad)? onOpened,
    void Function(Ad)? onClosed,
    void Function(Ad)? onImpression,
    void Function(Ad)? onClicked,
  }) {
    if (kIsWeb || !canServeAds) return null;

    final unitId = AdConfig.nativeAdUnitId;
    if (unitId.isEmpty) return null;

    NativeAd? nativeAd;
    nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: factoryId,
      nativeTemplateStyle: nativeTemplateStyle,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _activeAds.add(ad);
          onLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          _activeAds.remove(ad);
          ad.dispose();
          onFailed(ad, error);
        },
        onAdOpened: onOpened,
        onAdClosed: onClosed,
        onAdImpression: onImpression,
        onAdClicked: onClicked,
      ),
    );

    nativeAd.load();
    return nativeAd;
  }

  /// Open Ad Inspector in debug/test builds.
  Future<void> openAdInspector(BuildContext context) async {
    if (kIsWeb) return;
    try {
      MobileAds.instance.openAdInspector((error) {
        if (error != null) {
          AppLogger.debug(
            'AdInspector error: ${error.code} - ${error.message}',
          );
        }
      });
    } catch (e) {
      AppLogger.debug('Failed to open Ad Inspector: $e');
    }
  }

  /// Untrack and dispose an individual ad.
  void releaseAd(Ad ad) {
    _activeAds.remove(ad);
    ad.dispose();
  }

  /// Dispose all tracked active ads.
  void disposeAll() {
    for (final ad in _activeAds) {
      try {
        ad.dispose();
      } catch (_) {
        // Best-effort cleanup: an already-disposed ad may rethrow.
      }
    }
    _activeAds.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastBackgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _lastBackgroundedAt;
      if (pausedAt != null) {
        final elapsed = DateTime.now().difference(pausedAt);
        if (elapsed > const Duration(minutes: 30)) {
          AppLogger.debug('AdService: App resumed after >30min backgrounding.');
        }
      }
    }
  }

  @override
  void didHaveMemoryPressure() {
    AppLogger.debug(
      'AdService: Memory pressure detected. Disposing heavy ad objects.',
    );
    disposeAll();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeAll();
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});
