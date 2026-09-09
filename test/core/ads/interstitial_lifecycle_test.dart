import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/interstitial_ad_manager.dart';

import 'support/ad_lifecycle_fakes.dart';

void main() {
  testWidgets('late preload after provider disposal is released safely', (
    tester,
  ) async {
    final ad = TestInterstitial();
    final service = ControlledAdService(trackedAds: [ad]);
    final harness = await AdHarness.mount(tester, service);
    harness.container.read(interstitialAdManagerProvider);
    await tester.pump();
    harness.close();
    service.completeInterstitial(0, ad);
    await tester.pump();
    expect(service.claimed, contains(ad));
    expect(ad.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suppression rejects an old load and permits a later preload', (
    tester,
  ) async {
    final service = ControlledAdService();
    final harness = await AdHarness.mount(tester, service);
    final manager = harness.container.read(interstitialAdManagerProvider);
    await tester.pump();
    harness.state.allow(false);
    harness.state.allow(true);
    await tester.pump();
    expect(service.interstitialLoads.length, 2);
    final oldAd = TestInterstitial();
    final currentAd = TestInterstitial();
    service.completeInterstitial(0, oldAd);
    service.completeInterstitial(1, currentAd);
    await tester.pump();
    expect(oldAd.disposals, 1);
    expect(currentAd.disposals, 0);
    expect(await manager.showIfAllowed(harness.context, 'lesson_exit'), isTrue);
    expect(oldAd.shows, 0);
    expect(currentAd.shows, 1);
    expect(currentAd.disposals, 1);
  });

  testWidgets(
    'a native show exception returns false instead of escaping navigation',
    (tester) async {
      final ad = TestInterstitial()
        ..showError = PlatformException(code: 'invalid_native_ad');
      final service = ControlledAdService(trackedAds: [ad]);
      final harness = await AdHarness.mount(tester, service);
      final manager = harness.container.read(interstitialAdManagerProvider);
      await tester.pump();
      service.completeInterstitial(0, ad);
      await tester.pump();
      expect(
        await manager.showIfAllowed(harness.context, 'lesson_exit'),
        isFalse,
      );
      expect(ad.shows, 1);
      expect(ad.disposals, 1);
      ad.dismiss();
      await tester.pump();
      expect(ad.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('concurrent requests and changed consent cannot show an ad', (
    tester,
  ) async {
    final ad = TestInterstitial();
    final service = ControlledAdService();
    final harness = await AdHarness.mount(tester, service);
    final manager = harness.container.read(interstitialAdManagerProvider);
    await tester.pump();
    service.completeInterstitial(0, ad);
    await tester.pump();
    final consent = Completer<bool>();
    service.consent.pending = consent.future;
    final first = manager.showIfAllowed(harness.context, 'lesson_exit');
    bool? secondResult;
    unawaited(
      manager.showIfAllowed(harness.context, 'lesson_exit').then<void>((value) {
        secondResult = value;
      }),
    );
    await tester.pump();
    expect(secondResult, isFalse);
    harness.state.allow(false);
    consent.complete(true);
    await tester.pump();
    expect(await first, isFalse);
    expect(ad.shows, 0);
    expect(ad.disposals, 1);
  });

  testWidgets(
    'memory pressure drops a preload but not a displayed full-screen ad',
    (tester) async {
      final ad = TestInterstitial()..autoDismiss = false;
      final service = ControlledAdService(trackedAds: [ad]);
      final harness = await AdHarness.mount(tester, service);
      final manager = harness.container.read(interstitialAdManagerProvider);
      await tester.pump();
      service.completeInterstitial(0, ad);
      await tester.pump();
      final showing = manager.showIfAllowed(harness.context, 'lesson_exit');
      await tester.pump();
      expect(ad.shows, 1);
      service.didHaveMemoryPressure();
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(ad.disposals, 0);
      ad.dismiss();
      await tester.pump();
      expect(await showing, isTrue);
      expect(ad.disposals, 1);

      final preload = TestInterstitial();
      service.completeInterstitial(1, preload);
      await tester.pump();
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(preload.disposals, 1);
    },
  );

  testWidgets(
    'dismissal after provider disposal completes without reading a dead ref',
    (tester) async {
      final ad = TestInterstitial()..autoDismiss = false;
      final service = ControlledAdService(trackedAds: [ad]);
      final harness = await AdHarness.mount(tester, service);
      final manager = harness.container.read(interstitialAdManagerProvider);
      await tester.pump();
      service.completeInterstitial(0, ad);
      await tester.pump();
      final showing = manager.showIfAllowed(harness.context, 'lesson_exit');
      await tester.pump();
      harness.close();
      expect(await showing, isFalse);
      expect(ad.disposals, 0);
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
      ad.dismiss();
      await tester.pump();
      expect(ad.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
