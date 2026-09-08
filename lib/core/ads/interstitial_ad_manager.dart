import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import '../observability/crash_reporting.dart';
import 'ad_service.dart';
import 'ad_state.dart';

class InterstitialAdManager with WidgetsBindingObserver {
  final Ref _ref;
  final AdService _adService;
  bool _disposed = false;
  bool _isShowing = false;
  int _generation = 0;
  Completer<bool>? _presentation;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isCategorySwitchAdShownThisSession = false;

  InterstitialAdManager(this._ref)
    : _adService = _ref.read(adServiceProvider) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Preload an interstitial ad without retaining obsolete async results.
  Future<void> preload() async {
    if (_disposed) return;
    final adState = _ref.read(adStateProvider);
    if (!adState.shouldShowAds || _isLoading || _interstitialAd != null) return;
    _isLoading = true;
    final generation = ++_generation;
    try {
      final result = await _adService.loadInterstitialAd();
      if (!_disposed && generation == _generation) _isLoading = false;
      result.fold<void>(
        (error) {
          if (_disposed || generation != _generation) return;
          AppLogger.debug('InterstitialAdManager: Preload failed: ${error.message}');
          _ref.read(adStateProvider.notifier).recordError('interstitial');
        },
        (ad) {
          _adService.takeOwnership(ad);
          if (_disposed || generation != _generation ||
              !_ref.read(adStateProvider).shouldShowAds) {
            _adService.releaseAd(ad);
            return;
          }
          _interstitialAd = ad;
          _ref.read(adStateProvider.notifier).resetErrors('interstitial');
        },
      );
    } catch (error, stack) {
      if (!_disposed && generation == _generation) _isLoading = false;
      CrashReporting.recordError(error, stack);
    }
  }

  /// Show interstitial ad if permitted by frequency cap, trigger rules, and user tier.
  Future<bool> showIfAllowed(BuildContext context, String trigger) async {
    if (_disposed || _isShowing || !context.mounted) return false;
    _isShowing = true;
    try {
      return await _showIfAllowed(context, trigger);
    } catch (error, stack) {
      clearCachedAd();
      CrashReporting.recordError(error, stack);
      return false;
    } finally {
      _isShowing = false;
    }
  }

  Future<bool> _showIfAllowed(BuildContext context, String trigger) async {
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

    final consentAllowed = await _adService.consentManager.canRequestAds();
    if (_disposed || !context.mounted) {
      clearCachedAd();
      return false;
    }
    final currentState = _ref.read(adStateProvider);
    if (!consentAllowed || !currentState.shouldShowAds ||
        !currentState.canShowInterstitial() ||
        _interstitialAd == null) {
      clearCachedAd();
      return false;
    }

    final completer = Completer<bool>();
    _presentation = completer;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    var released = false;
    var ended = false;
    void releasePresentedAd() {
      if (released) return;
      released = true;
      _adService.releaseAd(ad);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (_disposed || ended) return;
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
        if (ended) return;
        ended = true;
        AppLogger.debug('InterstitialAdManager: Ad dismissed ($trigger)');
        releasePresentedAd();
        if (_disposed) {
          if (!completer.isCompleted) completer.complete(false);
          return;
        }
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
        if (ended) return;
        ended = true;
        AppLogger.debug(
          'InterstitialAdManager: Ad failed to show ($trigger): ${error.message}',
        );
        releasePresentedAd();
        if (_disposed) {
          if (!completer.isCompleted) completer.complete(false);
          return;
        }
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
        if (_disposed || ended) return;
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

    try {
      await ad.show();
      return await completer.future;
    } catch (error, stack) {
      ended = true;
      releasePresentedAd();
      if (!completer.isCompleted) completer.complete(false);
      CrashReporting.recordError(error, stack);
      return false;
    } finally {
      if (identical(_presentation, completer)) _presentation = null;
    }
  }

  /// Drop only a preload; a currently displayed ad finishes through callbacks.
  void clearCachedAd() {
    _generation++;
    _isLoading = false;
    final ad = _interstitialAd;
    _interstitialAd = null;
    if (ad != null) _adService.releaseAd(ad);
  }

  @override
  void didHaveMemoryPressure() => clearCachedAd();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    clearCachedAd();
    final presentation = _presentation;
    if (presentation != null && !presentation.isCompleted) {
      presentation.complete(false);
    }
  }
}

final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager(ref);
  // Kick off initial background preload
  Future.microtask(manager.preload);
  ref.listen<AdState>(adStateProvider, (previous, next) {
    if (next.shouldShowAds && previous?.shouldShowAds != true) {
      Future.microtask(manager.preload);
    } else if (!next.shouldShowAds) {
      manager.clearCachedAd();
    }
  });
  ref.onDispose(manager.dispose);
  return manager;
});
