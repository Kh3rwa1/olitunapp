import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/consent_manager.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('missing UMP platform and reset cannot authorize ad requests', () async {
    final consent = ConsentManager();
    expect(consent.requestsAllowed, isFalse);
    expect(await consent.canRequestAds(), isFalse);
    expect(consent.requestsAllowed, isFalse);
    await consent.reset();
    expect(consent.requestsAllowed, isFalse);
    expect(AdService.instance.canServeAds, isFalse);
  });
  test('eligibility changes preserve free rewards without requesting ads', () {
    const initial = AdState();
    expect(initial.shouldShowAds, isFalse);
    final allowed = initial.copyWith(consentAllowsAds: true);
    expect(allowed.shouldShowAds, isTrue);
    expect(
      allowed.copyWith(consentAllowsAds: false).canShowInterstitial(),
      isFalse,
    );
    expect(
      allowed.copyWith(consentAllowsAds: false).canShowRewarded(),
      isFalse,
    );
    expect(initial.copyWith(isAdFreeUser: true).canShowRewarded(), isTrue);
    expect(
      allowed.copyWith(isAdsEnabledGlobally: false).shouldShowAds,
      isFalse,
    );
  });
}
