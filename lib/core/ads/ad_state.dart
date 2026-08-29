import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../shared/providers/purchases_provider.dart';
import '../config/ad_config.dart';
import '../logging/app_logger.dart';

class AdState extends Equatable {
  final ConsentStatus consentStatus;
  final bool isAdFreeUser;
  final bool isAdsEnabledGlobally;
  final Map<String, int> adLoadErrors;
  final Map<String, int> adImpressionCounts;
  final DateTime? lastInterstitialShownAt;
  final DateTime? lastRewardedShownAt;
  final int interstitialIntervalMinutes;
  final int rewardedCooldownMinutes;

  const AdState({
    this.consentStatus = ConsentStatus.unknown,
    this.isAdFreeUser = false,
    this.isAdsEnabledGlobally = true,
    this.adLoadErrors = const {},
    this.adImpressionCounts = const {},
    this.lastInterstitialShownAt,
    this.lastRewardedShownAt,
    this.interstitialIntervalMinutes =
        AdConfig.defaultInterstitialIntervalMinutes,
    this.rewardedCooldownMinutes = AdConfig.defaultRewardedCooldownMinutes,
  });

  /// Whether ads can be displayed to this user.
  bool get shouldShowAds => isAdsEnabledGlobally && !isAdFreeUser;

  /// Check if interstitial ad is allowed based on frequency cap and user status.
  bool canShowInterstitial() {
    if (!shouldShowAds) return false;
    if (lastInterstitialShownAt == null) return true;

    final elapsed = DateTime.now().difference(lastInterstitialShownAt!);
    return elapsed >= Duration(minutes: interstitialIntervalMinutes);
  }

  /// Check if rewarded ad cooldown has elapsed.
  bool canShowRewarded() {
    if (isAdFreeUser) return true; // Ad-free users can claim rewards anytime
    if (!isAdsEnabledGlobally) return true;
    if (lastRewardedShownAt == null) return true;

    final elapsed = DateTime.now().difference(lastRewardedShownAt!);
    return elapsed >= Duration(minutes: rewardedCooldownMinutes);
  }

  /// Remaining seconds until next rewarded ad is available.
  int get remainingRewardedCooldownSeconds {
    if (lastRewardedShownAt == null) return 0;
    final target = lastRewardedShownAt!.add(
      Duration(minutes: rewardedCooldownMinutes),
    );
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AdState copyWith({
    ConsentStatus? consentStatus,
    bool? isAdFreeUser,
    bool? isAdsEnabledGlobally,
    Map<String, int>? adLoadErrors,
    Map<String, int>? adImpressionCounts,
    DateTime? lastInterstitialShownAt,
    DateTime? lastRewardedShownAt,
    int? interstitialIntervalMinutes,
    int? rewardedCooldownMinutes,
  }) {
    return AdState(
      consentStatus: consentStatus ?? this.consentStatus,
      isAdFreeUser: isAdFreeUser ?? this.isAdFreeUser,
      isAdsEnabledGlobally: isAdsEnabledGlobally ?? this.isAdsEnabledGlobally,
      adLoadErrors: adLoadErrors ?? this.adLoadErrors,
      adImpressionCounts: adImpressionCounts ?? this.adImpressionCounts,
      lastInterstitialShownAt:
          lastInterstitialShownAt ?? this.lastInterstitialShownAt,
      lastRewardedShownAt: lastRewardedShownAt ?? this.lastRewardedShownAt,
      interstitialIntervalMinutes:
          interstitialIntervalMinutes ?? this.interstitialIntervalMinutes,
      rewardedCooldownMinutes:
          rewardedCooldownMinutes ?? this.rewardedCooldownMinutes,
    );
  }

  @override
  List<Object?> get props => [
    consentStatus,
    isAdFreeUser,
    isAdsEnabledGlobally,
    adLoadErrors,
    adImpressionCounts,
    lastInterstitialShownAt,
    lastRewardedShownAt,
    interstitialIntervalMinutes,
    rewardedCooldownMinutes,
  ];
}

class AdStateNotifier extends Notifier<AdState> {
  final AdState? _initialState;

  AdStateNotifier([this._initialState]);

  @override
  AdState build() {
    if (_initialState != null) {
      return _initialState;
    }

    try {
      // Listen to purchased categories to reactively update ad-free state
      ref.listen<AsyncValue<Set<String>>>(purchasedCategoriesProvider, (
        prev,
        next,
      ) {
        next.whenData((categories) {
          final hasPurchases = categories.isNotEmpty;
          setIsAdFreeUser(hasPurchases);
        });
      });
    } catch (_) {
      // Defensive for headless test environments without full provider container setup
    }

    return const AdState();
  }

  void setConsentStatus(ConsentStatus status) {
    state = state.copyWith(consentStatus: status);
  }

  void setIsAdFreeUser(bool isAdFree) {
    if (state.isAdFreeUser != isAdFree) {
      AppLogger.debug('AdState: isAdFreeUser set to $isAdFree');
      state = state.copyWith(isAdFreeUser: isAdFree);
    }
  }

  void setGlobalAdsEnabled(bool enabled) {
    state = state.copyWith(isAdsEnabledGlobally: enabled);
  }

  void setInterstitialIntervalMinutes(int minutes) {
    state = state.copyWith(interstitialIntervalMinutes: minutes.clamp(1, 60));
  }

  void setRewardedCooldownMinutes(int minutes) {
    state = state.copyWith(rewardedCooldownMinutes: minutes.clamp(1, 60));
  }

  void recordImpression(String adFormat, [String? placement]) {
    final key = placement != null ? '${adFormat}_$placement' : adFormat;
    final counts = Map<String, int>.from(state.adImpressionCounts);
    counts[key] = (counts[key] ?? 0) + 1;

    final now = DateTime.now();
    if (adFormat == 'interstitial') {
      state = state.copyWith(
        adImpressionCounts: counts,
        lastInterstitialShownAt: now,
      );
    } else if (adFormat == 'rewarded') {
      state = state.copyWith(
        adImpressionCounts: counts,
        lastRewardedShownAt: now,
      );
    } else {
      state = state.copyWith(adImpressionCounts: counts);
    }
  }

  void recordError(String adFormat) {
    final errors = Map<String, int>.from(state.adLoadErrors);
    errors[adFormat] = (errors[adFormat] ?? 0) + 1;
    state = state.copyWith(adLoadErrors: errors);
  }

  void resetErrors(String adFormat) {
    if (state.adLoadErrors.containsKey(adFormat)) {
      final errors = Map<String, int>.from(state.adLoadErrors)
        ..remove(adFormat);
      state = state.copyWith(adLoadErrors: errors);
    }
  }
}

final adStateProvider = NotifierProvider<AdStateNotifier, AdState>(
  AdStateNotifier.new,
);
