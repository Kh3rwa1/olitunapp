import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

void main() {
  group('AdState and AdStateNotifier Tests', () {
    test(
      'default state requires ads for free users and allows initial interstitial/rewarded',
      () {
        const state = AdState();
        expect(state.isAdFreeUser, isFalse);
        expect(state.isAdsEnabledGlobally, isTrue);
        expect(state.shouldShowAds, isTrue);
        expect(state.canShowInterstitial(), isTrue);
        expect(state.canShowRewarded(), isTrue);
      },
    );

    test('ad-free user suppresses all ads and interstitial', () {
      const state = AdState(isAdFreeUser: true);
      expect(state.shouldShowAds, isFalse);
      expect(state.canShowInterstitial(), isFalse);
      // Ad-free users can claim rewards instantly without ads
      expect(state.canShowRewarded(), isTrue);
    });

    test('interstitial frequency cap suppresses ad within cooldown window', () {
      final now = DateTime.now();
      final state = AdState(
        lastInterstitialShownAt: now.subtract(const Duration(minutes: 2)),
        interstitialIntervalMinutes: 5,
      );
      expect(state.canShowInterstitial(), isFalse);

      final stateAfterCap = AdState(
        lastInterstitialShownAt: now.subtract(const Duration(minutes: 6)),
        interstitialIntervalMinutes: 5,
      );
      expect(stateAfterCap.canShowInterstitial(), isTrue);
    });

    test('rewarded cooldown enforces duration and remaining seconds', () {
      final now = DateTime.now();
      final state = AdState(
        lastRewardedShownAt: now.subtract(const Duration(minutes: 5)),
        rewardedCooldownMinutes: 15,
      );
      expect(state.canShowRewarded(), isFalse);
      expect(state.remainingRewardedCooldownSeconds, greaterThan(0));

      final readyState = AdState(
        lastRewardedShownAt: now.subtract(const Duration(minutes: 16)),
        rewardedCooldownMinutes: 15,
      );
      expect(readyState.canShowRewarded(), isTrue);
      expect(readyState.remainingRewardedCooldownSeconds, equals(0));
    });

    test('AdStateNotifier records impressions and errors accurately', () {
      final container = ProviderContainer(
        overrides: [
          purchasedCategoriesProvider.overrideWith(
            (ref) async => <String>{},
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adStateProvider.notifier);

      notifier.setConsentStatus(ConsentStatus.obtained);
      expect(
        container.read(adStateProvider).consentStatus,
        equals(ConsentStatus.obtained),
      );

      notifier.recordImpression('banner', 'home_bottom');
      expect(
        container
            .read(adStateProvider)
            .adImpressionCounts['banner_home_bottom'],
        equals(1),
      );

      notifier.recordError('banner');
      expect(container.read(adStateProvider).adLoadErrors['banner'], equals(1));

      notifier.resetErrors('banner');
      expect(
        container.read(adStateProvider).adLoadErrors.containsKey('banner'),
        isFalse,
      );

      notifier.setIsAdFreeUser(true);
      expect(container.read(adStateProvider).isAdFreeUser, isTrue);
      expect(container.read(adStateProvider).shouldShowAds, isFalse);
    });
  });
}
