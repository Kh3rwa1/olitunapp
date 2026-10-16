import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import '../observability/crash_reporting.dart';
import '../config/ad_config.dart';
import 'ad_service.dart';
import 'ad_state.dart';

enum RewardType { stars, quizAttempt, hearts, lessonUnlock }

class RewardedAdManager with WidgetsBindingObserver {
  final Ref _ref;
  final AdService _adService;
  bool _disposed = false;
  bool _isShowing = false;
  int _generation = 0;
  Completer<bool>? _presentation;

  RewardedAd? _rewardedAd;
  DateTime? _loadedAt;
  bool _isLoading = false;

  RewardedAdManager(this._ref) : _adService = _ref.read(adServiceProvider) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Preload a rewarded ad without retaining obsolete async results.
  Future<void> preload() async {
    if (_disposed) return;
    final adState = _ref.read(adStateProvider);
    if (!adState.shouldShowAds || _isLoading || _rewardedAd != null) return;
    _isLoading = true;
    final generation = ++_generation;
    try {
      final result = await _adService.loadRewardedAd();
      if (!_disposed && generation == _generation) _isLoading = false;
      result.fold<void>(
        (error) {
          if (_disposed || generation != _generation) return;
          AppLogger.debug(
            'RewardedAdManager: Preload failed: ${error.message}',
          );
          _ref.read(adStateProvider.notifier).recordError('rewarded');
        },
        (ad) {
          _adService.takeOwnership(ad);
          if (_disposed ||
              generation != _generation ||
              !_ref.read(adStateProvider).shouldShowAds) {
            _adService.releaseAd(ad);
            return;
          }
          _rewardedAd = ad;
          _loadedAt = DateTime.now();
          _ref.read(adStateProvider.notifier).resetErrors('rewarded');
        },
      );
    } catch (error, stack) {
      if (!_disposed && generation == _generation) _isLoading = false;
      CrashReporting.recordError(error, stack);
    }
  }

  /// Show rewarded ad and invoke onUserEarnedReward on success.
  /// If user is Ad-Free, invokes reward callback immediately without displaying an ad.
  Future<bool> show({
    required BuildContext context,
    required String placement,
    required RewardType rewardType,
    required int amount,
    required FutureOr<void> Function() onRewardGranted,
  }) async {
    if (_disposed || _isShowing || !context.mounted) return false;
    _isShowing = true;
    try {
      return await _show(
        context: context,
        placement: placement,
        rewardType: rewardType,
        amount: amount,
        onRewardGranted: onRewardGranted,
      );
    } catch (error, stack) {
      clearCachedAd();
      CrashReporting.recordError(error, stack);
      return false;
    } finally {
      _isShowing = false;
    }
  }

  Future<bool> _show({
    required BuildContext context,
    required String placement,
    required RewardType rewardType,
    required int amount,
    required FutureOr<void> Function() onRewardGranted,
  }) async {
    final adState = _ref.read(adStateProvider);

    // Rule: Ad-free users get reward instantly without watching
    if (adState.isAdFreeUser || !adState.isAdsEnabledGlobally) {
      AppLogger.debug(
        'RewardedAdManager: Ad-free user instant reward granted ($placement)',
      );
      await _grantReward(rewardType, amount);
      if (_disposed || !context.mounted) return false;
      await onRewardGranted();
      return true;
    }

    if (!adState.canShowRewarded()) {
      AppLogger.debug(
        'RewardedAdManager: Cooldown in effect for placement: $placement',
      );
      return false;
    }

    final loadedAt = _loadedAt;
    if (_rewardedAd != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) > AdConfig.fullScreenAdTtl) {
      clearCachedAd();
    }

    if (_rewardedAd == null) {
      AppLogger.debug(
        'RewardedAdManager: Ad not ready for placement: $placement',
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
    if (!consentAllowed ||
        !currentState.shouldShowAds ||
        !currentState.canShowRewarded() ||
        _rewardedAd == null) {
      clearCachedAd();
      return false;
    }

    final completer = Completer<bool>();
    _presentation = completer;
    final ad = _rewardedAd!;
    _rewardedAd = null;
    bool rewardEarned = false;
    var ended = false;
    var showFailed = false;
    final showAccepted = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (_disposed || ended) return;
        AppLogger.debug('RewardedAdManager: Ad showed ($placement)');
        _ref
            .read(adStateProvider.notifier)
            .recordImpression('rewarded', placement);
        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.impression,
                  adFormat: 'rewarded',
                  placement: placement,
                  rewardAmount: amount,
                  rewardType: rewardType.name,
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'RewardedAdManager: failed to log impression event: $e',
          );
        }
      },
      onAdDismissedFullScreenContent: (ad) async {
        if (ended) return;
        ended = true;
        _adService.markFullScreenAdShowing(false);
        AppLogger.debug('RewardedAdManager: Ad dismissed ($placement)');
        _adService.releaseAd(ad);
        await showAccepted.future;
        if (_disposed || showFailed || !context.mounted) {
          if (!completer.isCompleted) completer.complete(false);
          return;
        }
        try {
          _ref
              .read(learningAnalyticsServiceProvider)
              .logAdEvent(
                AdEvent(
                  type: AdEventType.dismissed,
                  adFormat: 'rewarded',
                  placement: placement,
                ),
              );
        } catch (e) {
          AppLogger.warning(
            'RewardedAdManager: failed to log dismissed event: $e',
          );
        }

        var granted = false;
        try {
          if (rewardEarned) {
            await _grantReward(rewardType, amount);
            if (!_disposed && context.mounted) {
              await onRewardGranted();
              granted = true;
            }
          }
        } catch (error, stack) {
          CrashReporting.recordError(error, stack);
        } finally {
          unawaited(preload());
          if (!completer.isCompleted) completer.complete(granted);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (ended) return;
        ended = true;
        _adService.markFullScreenAdShowing(false);
        showFailed = true;
        AppLogger.debug(
          'RewardedAdManager: Ad failed to show ($placement): ${error.message}',
        );
        _adService.releaseAd(ad);
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
                  adFormat: 'rewarded',
                  placement: placement,
                  errorCode: error.code.toString(),
                ),
              );
        } catch (e) {
          AppLogger.warning('RewardedAdManager: failed to log error event: $e');
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
                  adFormat: 'rewarded',
                  placement: placement,
                ),
              );
        } catch (e) {
          AppLogger.warning('RewardedAdManager: failed to log click event: $e');
        }
      },
    );

    try {
      _adService.markFullScreenAdShowing(true);
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          if (_disposed || ended || showFailed) return;
          AppLogger.debug(
            'RewardedAdManager: User earned reward: ${reward.amount} ${reward.type}',
          );
          rewardEarned = true;
          try {
            _ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.reward,
                    adFormat: 'rewarded',
                    placement: placement,
                    rewardAmount: amount,
                    rewardType: rewardType.name,
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'RewardedAdManager: failed to log impression event: $e',
            );
          }
        },
      );

      showAccepted.complete();
      return await completer.future;
    } catch (error, stack) {
      showFailed = true;
      ended = true;
      _adService.markFullScreenAdShowing(false);
      _adService.releaseAd(ad);
      if (!completer.isCompleted) completer.complete(false);
      CrashReporting.recordError(error, stack);
      return false;
    } finally {
      if (!showAccepted.isCompleted) showAccepted.complete();
      if (identical(_presentation, completer)) _presentation = null;
    }
  }

  Future<void> _grantReward(RewardType type, int amount) async {
    try {
      switch (type) {
        case RewardType.stars:
          await _ref.read(rewardStarsGranterProvider)(amount);
          AppLogger.debug('RewardedAdManager: Credited $amount stars to user');
          break;
        case RewardType.quizAttempt:
        case RewardType.hearts:
        case RewardType.lessonUnlock:
          // User awarded free attempt or hearts refill
          AppLogger.debug(
            'RewardedAdManager: Refilled $amount hearts / quiz attempts',
          );
          break;
      }
    } catch (e) {
      AppLogger.debug('RewardedAdManager: Failed to grant reward: $e');
    }
  }

  /// Drop only a preload; a currently displayed ad finishes through callbacks.
  void clearCachedAd() {
    _generation++;
    _isLoading = false;
    final ad = _rewardedAd;
    _rewardedAd = null;
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

/// Credits stars earned from a rewarded ad to the learner's stats.
typedef RewardStarsGranter = Future<void> Function(int amount);

/// Core cannot depend on the profile feature, so the app root
/// (`lib/main.dart`) overrides this with the user-stats notifier. Without an
/// override, granting stars fails and is logged by `_grantReward`.
final rewardStarsGranterProvider = Provider<RewardStarsGranter>(
  (ref) =>
      (_) => throw StateError(
        'rewardStarsGranterProvider must be overridden at the app root',
      ),
);

final rewardedAdManagerProvider = Provider<RewardedAdManager>((ref) {
  final manager = RewardedAdManager(ref);
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
