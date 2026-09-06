import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/ad_config.dart';

void main() {
  group('AdConfig Tests', () {
    test('provides test ad unit IDs by default in test mode', () {
      expect(AdConfig.isTestMode, isTrue);
      expect(AdConfig.bannerAdUnitId, isNotEmpty);
      expect(AdConfig.interstitialAdUnitId, isNotEmpty);
      expect(AdConfig.rewardedAdUnitId, isNotEmpty);
      expect(AdConfig.nativeAdUnitId, isNotEmpty);
    });

    test('default frequency caps have reasonable limits', () {
      expect(AdConfig.defaultInterstitialIntervalMinutes, equals(3));
      expect(AdConfig.defaultRewardedCooldownMinutes, equals(10));
    });

    test('provides non-empty sample fallback ad unit IDs', () {
      expect(AdConfig.fallbackBannerAdUnitId, isNotEmpty);
      expect(AdConfig.fallbackInterstitialAdUnitId, isNotEmpty);
      expect(AdConfig.fallbackRewardedAdUnitId, isNotEmpty);
      expect(AdConfig.fallbackNativeAdUnitId, isNotEmpty);
    });
  });
}
