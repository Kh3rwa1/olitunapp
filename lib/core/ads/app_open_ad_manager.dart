import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../analytics/analytics_service.dart';
import '../config/ad_config.dart';
import '../logging/app_logger.dart';
import '../observability/crash_reporting.dart';
import '../storage/hive_service.dart';
import 'ad_service.dart';
import 'ad_state.dart';

/// App open ads: shown when a returning learner launches the app, or comes
/// back after [AdConfig.appOpenMinBackground]. Never on the first launch,
/// never over another full-screen ad, and never on routes the app marks as
/// blocked (onboarding, login, mid-quiz).
class AppOpenAdManager with WidgetsBindingObserver {
  final Ref _ref;
  final AdService _adService;
  final int _launchCount;
  final DateTime _createdAt = DateTime.now();

  /// Set by the app shell. Returns false on routes where an ad would
  /// interrupt (onboarding, login, an active quiz).
  bool Function(bool coldStart) routeAllowsAd = (_) => true;

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _disposed = false;
  bool _coldStartPending = true;
  DateTime? _pausedAt;
  int _generation = 0;

  static const _launchCountKey = 'ads_app_open_launch_count';
  static const _coldStartWindow = Duration(seconds: 6);
  static const _afterFullScreenGap = Duration(seconds: 60);

  AppOpenAdManager(this._ref, {required int launchCount})
    : _adService = _ref.read(adServiceProvider),
      _launchCount = launchCount {
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _isReturningUser => _launchCount >= 2;

  bool get _isExpired {
    final loadedAt = _loadedAt;
    return loadedAt == null ||
        DateTime.now().difference(loadedAt) > AdConfig.appOpenAdTtl;
  }

  Future<void> preload() async {
    if (_disposed || _isLoading) return;
    if (!_ref.read(adStateProvider).shouldShowAds) return;
    if (AdConfig.appOpenAdUnitId.isEmpty) return;
    if (_ad != null && !_isExpired) return;
    if (_ad != null) clearCachedAd();

    _isLoading = true;
    final generation = ++_generation;
    try {
      final result = await _adService.loadAppOpenAd();
      if (_disposed || generation != _generation) {
        result.fold((_) {}, _adService.releaseAd);
        return;
      }
      _isLoading = false;
      result.fold(
        (error) {
          AppLogger.debug('AppOpenAdManager: load failed: ${error.message}');
          _ref.read(adStateProvider.notifier).recordError('app_open');
        },
        (ad) {
          _adService.takeOwnership(ad);
          if (!_ref.read(adStateProvider).shouldShowAds) {
            _adService.releaseAd(ad);
            return;
          }
          _ad = ad;
          _loadedAt = DateTime.now();
          _maybeShowOnColdStart();
        },
      );
    } catch (error, stack) {
      if (!_disposed && generation == _generation) _isLoading = false;
      CrashReporting.recordError(error, stack);
    }
  }

  void _maybeShowOnColdStart() {
    if (!_coldStartPending) return;
    _coldStartPending = false;
    if (!_isReturningUser) return;
    if (DateTime.now().difference(_createdAt) > _coldStartWindow) return;
    unawaited(_showIfAllowed('app_launch', coldStart: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused) {
      _coldStartPending = false;
      // A full-screen ad also pauses the activity; that is not a real exit.
      if (!_adService.isFullScreenAdShowing) _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      final skip = _adService.consumeAppOpenSkip();
      if (pausedAt == null || skip) return;
      if (DateTime.now().difference(pausedAt) < AdConfig.appOpenMinBackground) {
        return;
      }
      unawaited(_showIfAllowed('app_resume', coldStart: false));
    }
  }

  Future<bool> _showIfAllowed(String trigger, {required bool coldStart}) async {
    if (_disposed || _isShowing) return false;
    final adState = _ref.read(adStateProvider);
    if (!adState.canShowAppOpen()) return false;
    if (_adService.isFullScreenAdShowing) return false;
    final lastEnded = _adService.lastFullScreenEndedAt;
    if (lastEnded != null &&
        DateTime.now().difference(lastEnded) < _afterFullScreenGap) {
      return false;
    }
    if (!routeAllowsAd(coldStart)) return false;

    final ad = _ad;
    if (ad == null || _isExpired) {
      unawaited(preload());
      return false;
    }
    if (!await _adService.consentManager.canRequestAds() || _disposed) {
      return false;
    }

    _ad = null;
    _loadedAt = null;
    _isShowing = true;
    final completer = Completer<bool>();
    var ended = false;
    void finish(bool shown) {
      if (ended) return;
      ended = true;
      _isShowing = false;
      _adService.markFullScreenAdShowing(false);
      _adService.releaseAd(ad);
      if (!completer.isCompleted) completer.complete(shown);
      if (!_disposed) unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (_disposed || ended) return;
        _ref.read(adStateProvider.notifier).recordImpression('app_open');
        _logEvent(AdEventType.impression, trigger);
      },
      onAdDismissedFullScreenContent: (_) {
        _logEvent(AdEventType.dismissed, trigger);
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        AppLogger.debug('AppOpenAdManager: show failed: ${error.message}');
        _logEvent(AdEventType.error, trigger, error.code.toString());
        finish(false);
      },
      onAdClicked: (_) => _logEvent(AdEventType.click, trigger),
    );

    try {
      _adService.markFullScreenAdShowing(true);
      await ad.show();
      return await completer.future;
    } catch (error, stack) {
      CrashReporting.recordError(error, stack);
      finish(false);
      return false;
    }
  }

  void _logEvent(AdEventType type, String placement, [String? errorCode]) {
    if (_disposed) return;
    try {
      _ref
          .read(learningAnalyticsServiceProvider)
          .logAdEvent(
            AdEvent(
              type: type,
              adFormat: 'app_open',
              placement: placement,
              errorCode: errorCode,
            ),
          );
    } catch (e) {
      AppLogger.warning('AppOpenAdManager: failed to log event: $e');
    }
  }

  void clearCachedAd() {
    _generation++;
    _isLoading = false;
    final ad = _ad;
    _ad = null;
    _loadedAt = null;
    if (ad != null) _adService.releaseAd(ad);
  }

  @override
  void didHaveMemoryPressure() => clearCachedAd();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    clearCachedAd();
  }

  /// Bumps and returns the persisted launch counter.
  static int recordLaunch(Ref ref) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final count = (prefs.getInt(_launchCountKey) ?? 0) + 1;
      unawaited(prefs.setInt(_launchCountKey, count));
      return count;
    } catch (_) {
      return 1;
    }
  }
}

final appOpenAdManagerProvider = Provider<AppOpenAdManager>((ref) {
  final manager = AppOpenAdManager(
    ref,
    launchCount: AppOpenAdManager.recordLaunch(ref),
  );
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
