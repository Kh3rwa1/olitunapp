import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:itun/core/ads/ad_remote_config.dart';
import 'package:itun/core/ads/ad_service.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';
import 'package:itun/core/config/ad_config.dart';
import 'package:itun/main.dart' show appOpenAllowedOn;

import 'support/ad_lifecycle_fakes.dart';

LoadAdError _error(int code) => LoadAdError(code, 'test', 'error $code', null);

void main() {
  group('no-fill pause', () {
    test('pauses a format after the streak limit and resets on fill', () {
      final service = AdService.forTesting();
      for (var i = 1; i < AdConfig.noFillStreakLimit; i++) {
        expect(service.recordNoFill('banner'), isFalse);
      }
      expect(service.noFillWait('banner'), Duration.zero);
      expect(service.recordNoFill('banner'), isTrue);
      expect(service.noFillWait('banner'), greaterThan(Duration.zero));
      expect(service.noFillWait('native'), Duration.zero);

      service.recordFill('banner');
      expect(service.noFillWait('banner'), Duration.zero);
    });

    test('only error code 3 counts as no fill', () {
      expect(AdService.isNoFill(_error(3)), isTrue);
      expect(AdService.isNoFill(_error(2)), isFalse);
      expect(AdService.isNoFill(_error(0)), isFalse);
    });

    test('a hand-off skip is consumed once', () {
      final service = AdService.forTesting();
      expect(service.consumeAppOpenSkip(), isFalse);
      service.skipNextAppOpen();
      expect(service.consumeAppOpenSkip(), isTrue);
      expect(service.consumeAppOpenSkip(), isFalse);
    });
  });

  group('app open gating', () {
    test('respects its own gap and the interstitial cap', () {
      final now = DateTime.now();
      expect(const AdState(consentAllowsAds: true).canShowAppOpen(), isTrue);
      expect(const AdState().canShowAppOpen(), isFalse);
      expect(
        AdState(
          consentAllowsAds: true,
          lastAppOpenShownAt: now.subtract(const Duration(minutes: 30)),
          appOpenIntervalMinutes: 120,
        ).canShowAppOpen(),
        isFalse,
      );
      expect(
        AdState(
          consentAllowsAds: true,
          lastInterstitialShownAt: now.subtract(const Duration(seconds: 30)),
        ).canShowAppOpen(),
        isFalse,
      );
      expect(
        AdState(
          consentAllowsAds: true,
          lastAppOpenShownAt: now.subtract(const Duration(hours: 3)),
          appOpenIntervalMinutes: 120,
        ).canShowAppOpen(),
        isTrue,
      );
    });

    test('blocks sign-up and active-session routes', () {
      expect(appOpenAllowedOn('/', coldStart: false), isTrue);
      expect(appOpenAllowedOn('/lessons/abc', coldStart: false), isTrue);
      expect(appOpenAllowedOn('/splash', coldStart: true), isTrue);
      expect(appOpenAllowedOn('/splash', coldStart: false), isFalse);
      for (final path in [
        '/onboarding',
        '/login',
        '/welcome',
        '/quiz/q1',
        '/review',
        '/practice/a/b',
        '/admin/settings',
      ]) {
        expect(appOpenAllowedOn(path, coldStart: false), isFalse, reason: path);
      }
    });
  });

  group('remote settings', () {
    tearDown(AdConfig.clearRemoteUnitIds);

    test('apply kill switch and caps to ad state', () {
      final container = ProviderContainer(
        overrides: [
          adStateProvider.overrideWith(
            () => AdStateNotifier(const AdState(consentAllowsAds: true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      applyAdRemoteSettings(container.read(adStateProvider.notifier), {
        'admob_enabled_free_tier': 'false',
        'admob_interstitial_cap_minutes': '4',
        'admob_rewarded_cooldown_minutes': '7',
        'admob_app_open_cap_minutes': '90',
      });
      final state = container.read(adStateProvider);
      expect(state.isAdsEnabledGlobally, isFalse);
      expect(state.interstitialIntervalMinutes, 4);
      expect(state.rewardedCooldownMinutes, 7);
      expect(state.appOpenIntervalMinutes, 90);

      applyAdRemoteSettings(container.read(adStateProvider.notifier), {
        'admob_interstitial_cap_minutes': 'oops',
      });
      final defaults = container.read(adStateProvider);
      expect(defaults.isAdsEnabledGlobally, isTrue);
      expect(
        defaults.interstitialIntervalMinutes,
        AdConfig.defaultInterstitialIntervalMinutes,
      );
    });

    test('remote unit IDs never replace test units in test mode', () {
      AdConfig.applyRemoteUnitIds({'banner': 'ca-app-pub-1/2'});
      expect(AdConfig.isTestMode, isTrue);
      expect(AdConfig.bannerAdUnitId, isNot('ca-app-pub-1/2'));
      expect(AdConfig.appOpenAdUnitId, isNotEmpty);
    });
  });

  group('native slot fallback', () {
    testWidgets('a native no-fill fills the slot with a banner', (
      tester,
    ) async {
      final service = ControlledAdService();
      await AdHarness.mount(
        tester,
        service,
        child: const NativeAdWidget(),
        runtime: ControlledAdRuntime(),
      );
      final native = service.nativeLoads.single;
      native.failed(native.ad, _error(3));
      await tester.pump();

      expect(service.bannerLoads, hasLength(1));
      service.bannerLoads.single.complete();
      await tester.pump();
      expect(service.claimed, contains(service.bannerLoads.single.ad));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a network error retries native later, not instantly', (
      tester,
    ) async {
      final service = ControlledAdService();
      await AdHarness.mount(
        tester,
        service,
        child: const NativeAdWidget(),
        runtime: ControlledAdRuntime(),
      );
      final native = service.nativeLoads.single;
      native.failed(native.ad, _error(2));
      await tester.pump(const Duration(seconds: 2));
      expect(service.nativeLoads, hasLength(1));
      expect(service.bannerLoads, isEmpty);
      await tester.pump(const Duration(seconds: 4));
      expect(service.nativeLoads, hasLength(2));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
