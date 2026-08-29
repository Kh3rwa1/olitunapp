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
  });
}
