import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import 'ad_service.dart';
import 'ad_state.dart';

enum RewardType { stars, quizAttempt, hearts }

class RewardedAdManager {
  final Ref _ref;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  RewardedAdManager(this._ref);

  /// Preload a rewarded ad.
  Future<void> preload() async {
    final adState = _ref.read(adStateProvider);
    if (adState.isAdFreeUser || _isLoading || _rewardedAd != null) {
      return;
    }

    _isLoading = true;
    final adService = _ref.read(adServiceProvider);
    final result = await adService.loadRewardedAd();

    _isLoading = false;
    result.fold(
      (error) {
        AppLogger.debug('RewardedAdManager: Preload failed: ${error.message}');
        _ref.read(adStateProvider.notifier).recordError('rewarded');
      },
      (ad) {
        _rewardedAd = ad;
        _ref.read(adStateProvider.notifier).resetErrors('rewarded');
        AppLogger.debug(
          'RewardedAdManager: Rewarded ad preloaded successfully',
        );
      },
    );
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
    final adState = _ref.read(adStateProvider);

    // Rule: Ad-free users get reward instantly without watching
    if (adState.isAdFreeUser || !adState.isAdsEnabledGlobally) {
      AppLogger.debug(
        'RewardedAdManager: Ad-free user instant reward granted ($placement)',
      );
      await _grantReward(rewardType, amount);
      await onRewardGranted();
      return true;
    }

    if (!adState.canShowRewarded()) {
      AppLogger.debug(
        'RewardedAdManager: Cooldown in effect for placement: $placement',
      );
      return false;
    }

    if (_rewardedAd == null) {
      AppLogger.debug(
        'RewardedAdManager: Ad not ready for placement: $placement',
      );
      unawaited(preload());
      return false;
    }

    final completer = Completer<bool>();
    final ad = _rewardedAd!;
    _rewardedAd = null;
    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
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
        AppLogger.debug('RewardedAdManager: Ad dismissed ($placement)');
        ad.dispose();
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

        if (rewardEarned) {
          await _grantReward(rewardType, amount);
          await onRewardGranted();
        }

        unawaited(preload());
        if (!completer.isCompleted) completer.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.debug(
          'RewardedAdManager: Ad failed to show ($placement): ${error.message}',
        );
        ad.dispose();
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

    await ad.show(
      onUserEarnedReward: (ad, reward) {
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

    return completer.future;
  }

  Future<void> _grantReward(RewardType type, int amount) async {
    try {
      switch (type) {
        case RewardType.stars:
          await _ref.read(userStatsProvider.notifier).addStars(amount);
          AppLogger.debug('RewardedAdManager: Credited $amount stars to user');
          break;
        case RewardType.quizAttempt:
        case RewardType.hearts:
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

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

final rewardedAdManagerProvider = Provider<RewardedAdManager>((ref) {
  final manager = RewardedAdManager(ref);
  Future.microtask(manager.preload);
  ref.onDispose(manager.dispose);
  return manager;
});
