import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/rewarded_ad_manager.dart';

import 'support/ad_lifecycle_fakes.dart';

void main() {
  testWidgets('late rewarded preload is released after provider disposal', (
    tester,
  ) async {
    final ad = TestRewarded();
    final service = ControlledAdService(trackedAds: [ad]);
    final harness = await AdHarness.mount(tester, service);
    harness.container.read(rewardedAdManagerProvider);
    await tester.pump();
    harness.close();
    service.completeRewarded(0, ad);
    await tester.pump();
    expect(service.claimed, contains(ad));
    expect(ad.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'memory pressure preserves a displayed reward and duplicate callbacks grant once',
    (tester) async {
      final ad = TestRewarded()..autoDismiss = false;
      final service = ControlledAdService(trackedAds: [ad]);
      final harness = await AdHarness.mount(tester, service);
      final manager = harness.container.read(rewardedAdManagerProvider);
      await tester.pump();
      service.completeRewarded(0, ad);
      await tester.pump();
      var grants = 0;
      final showing = manager.show(
        context: harness.context,
        placement: 'test_hearts',
        rewardType: RewardType.hearts,
        amount: 1,
        onRewardGranted: () {
          grants++;
        },
      );
      await tester.pump();
      service.didHaveMemoryPressure();
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(ad.shows, 1);
      expect(ad.disposals, 0);
      expect(grants, 0);
      ad.dismiss();
      ad.dismiss();
      await tester.pump();
      expect(await showing, isTrue);
      expect(grants, 1);
      expect(ad.disposals, 1);
    },
  );

  for (final earlyCallbacks in [false, true]) {
    testWidgets(
      'native reward show failure grants nothing (early callbacks: $earlyCallbacks)',
      (tester) async {
        final ad = TestRewarded()
          ..callbacksBeforeError = earlyCallbacks
          ..showError = PlatformException(code: 'invalid_native_ad');
        final service = ControlledAdService(trackedAds: [ad]);
        final harness = await AdHarness.mount(tester, service);
        final manager = harness.container.read(rewardedAdManagerProvider);
        await tester.pump();
        service.completeRewarded(0, ad);
        await tester.pump();
        var grants = 0;
        expect(
          await manager.show(
            context: harness.context,
            placement: 'test_hearts',
            rewardType: RewardType.hearts,
            amount: 1,
            onRewardGranted: () {
              grants++;
            },
          ),
          isFalse,
        );
        ad.earn();
        ad.dismiss();
        await tester.pump();
        expect(grants, 0);
        expect(ad.disposals, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a failing reward callback completes false rather than leaving show pending',
    (tester) async {
      final ad = TestRewarded();
      final service = ControlledAdService();
      final harness = await AdHarness.mount(tester, service);
      final manager = harness.container.read(rewardedAdManagerProvider);
      await tester.pump();
      service.completeRewarded(0, ad);
      await tester.pump();
      final result = manager.show(
        context: harness.context,
        placement: 'test_hearts',
        rewardType: RewardType.hearts,
        amount: 1,
        onRewardGranted: () async {
          throw StateError('synthetic callback failure');
        },
      );
      await tester.pump();
      expect(await result, isFalse);
      expect(ad.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an unearned dismissal never grants a reward', (tester) async {
    final ad = TestRewarded()..autoEarn = false;
    final service = ControlledAdService();
    final harness = await AdHarness.mount(tester, service);
    final manager = harness.container.read(rewardedAdManagerProvider);
    await tester.pump();
    service.completeRewarded(0, ad);
    await tester.pump();
    var grants = 0;
    final result = manager.show(
      context: harness.context,
      placement: 'test_hearts',
      rewardType: RewardType.hearts,
      amount: 1,
      onRewardGranted: () {
        grants++;
      },
    );
    await tester.pump();
    expect(await result, isFalse);
    expect(grants, 0);
    expect(ad.disposals, 1);
  });
}
