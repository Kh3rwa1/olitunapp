import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;
import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import 'ad_service.dart';
import 'ad_state.dart';

class InterstitialAdManager {
  final Ref _ref;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isCategorySwitchAdShownThisSession = false;

  InterstitialAdManager(this._ref);

  /// Preload an interstitial ad so it is ready when needed.
  Future<void> preload() async {
    final adState = _ref.read(adStateProvider);
    if (!adState.shouldShowAds || _isLoading || _interstitialAd != null) {
      return;
    }

    _isLoading = true;
    final adService = _ref.read(adServiceProvider);
    final result = await adService.loadInterstitialAd();

    _isLoading = false;
    result.fold(
      (error) {
        AppLogger.debug(
          'InterstitialAdManager: Preload failed: ${error.message}',
        );
        _ref.read(adStateProvider.notifier).recordError('interstitial');
      },
      (ad) {
        _interstitialAd = ad;
        _ref.read(adStateProvider.notifier).resetErrors('interstitial');
        AppLogger.debug(
          'InterstitialAdManager: Interstitial ad preloaded successfully',
        );
      },
    );
  }

  /// Show interstitial ad if permitted by frequency cap, trigger rules, and user tier.
  Future<bool> showIfAllowed(BuildContext context, String trigger) async {
    final adState = _ref.read(adStateProvider);

    if (!adState.shouldShowAds) {
      AppLogger.debug(
        'InterstitialAdManager: Suppressed ($trigger) - User is ad-free or ads disabled',
      );
      return false;
    }

    // Special trigger constraint: Category switch is limited to max once per app session
    if (trigger == 'category_switch') {
      if (_isCategorySwitchAdShownThisSession) {
        AppLogger.debug(
          'InterstitialAdManager: Suppressed (category_switch already shown this session)',
        );
        return false;
      }
    }

    if (!adState.canShowInterstitial()) {
      AppLogger.debug(
        'InterstitialAdManager: Suppressed ($trigger) - Frequency cap active',
      );
      return false;
    }

    if (_interstitialAd == null) {
      AppLogger.debug(
        'InterstitialAdManager: Ad not ready for trigger: $trigger',
      );
      unawaited(preload());
      return false;
    }

    final completer = Completer<bool>();
    final ad = _interstitialAd!;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AppLogger.debug('InterstitialAdManager: Ad showed ($trigger)');
        _ref
            .read(adStateProvider.notifier)
            .recordImpression('interstitial', trigger);
        if (trigger == 'category_switch') {
          _isCategorySwitchAdShownThisSession = true;
        }

        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.impression,
                  adFormat: 'interstitial',
                  placement: trigger,
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'InterstitialAdManager: failed to log impression event: $e',
          );
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.debug('InterstitialAdManager: Ad dismissed ($trigger)');
        ad.dispose();
        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.dismissed,
                  adFormat: 'interstitial',
                  placement: trigger,
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'InterstitialAdManager: failed to log dismissed event: $e',
          );
        }
        // Preload next ad
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.debug(
          'InterstitialAdManager: Ad failed to show ($trigger): ${error.message}',
        );
        ad.dispose();
        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.error,
                  adFormat: 'interstitial',
                  placement: trigger,
                  errorCode: error.code.toString(),
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'InterstitialAdManager: failed to log error event: $e',
          );
        }
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdClicked: (ad) {
        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.click,
                  adFormat: 'interstitial',
                  placement: trigger,
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'InterstitialAdManager: failed to log click event: $e',
          );
        }
      },
    );

    await ad.show();
    return completer.future;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager(ref);
  // Kick off initial background preload
  Future.microtask(manager.preload);
  ref.onDispose(manager.dispose);
  return manager;
});
