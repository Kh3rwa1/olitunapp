import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';

import 'support/ad_lifecycle_fakes.dart';

void main() {
  for (final native in [true, false]) {
    final format = native ? 'native' : 'banner';
    final child = native ? const NativeAdWidget() : const BannerAdWidget();

    testWidgets('$format waits for load and frees a mounted ad only after its view leaves', (tester) async {
      final AdWithView first;
      if (native) { first = TestNative(); } else { first = TestBanner(); }
      final probe = (first as HasAdProbe).probe;
      final service = ControlledAdService(trackedAds: [first]);
      if (native) { service.firstNative = first as TestNative; }
      else { service.firstBanner = first as TestBanner; }
      final runtime = ControlledAdRuntime();
      await AdHarness.mount(tester, service, child: child, runtime: runtime);
      expect(probe.viewMounted, isFalse);
      final load = native ? service.nativeLoads.single : service.bannerLoads.single;
      load.complete();
      await tester.pump();
      expect(service.claimed, contains(first));
      expect(probe.viewMounted, isTrue);
      service.didHaveMemoryPressure();
      expect(probe.disposals, 0);
      tester.binding.handleMemoryPressure();
      expect(probe.disposals, 0);
      await tester.pump();
      expect(probe.viewMounted, isFalse);
      expect(probe.disposals, 1);
      expect(probe.disposedWhileMounted, 0);
      expect(runtime.invalidBuilds, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$format clears loaded state and rejects stale callbacks on refresh', (tester) async {
      final service = ControlledAdService();
      final runtime = ControlledAdRuntime();
      final harness = await AdHarness.mount(tester, service, child: child, runtime: runtime);
      final first = native ? service.nativeLoads.single : service.bannerLoads.single;
      final oldProbe = (first.ad as HasAdProbe).probe;
      first.complete();
      await tester.pump();
      expect(oldProbe.viewMounted, isTrue);
      harness.state.allow(false);
      harness.state.allow(true);
      await tester.pump();
      await tester.pump();
      final pending = native ? service.nativeLoads.last : service.bannerLoads.last;
      expect(identical(first.ad, pending.ad), isFalse);
      final probe = (pending.ad as HasAdProbe).probe;
      expect(oldProbe.disposals, 1);
      expect(oldProbe.disposedWhileMounted, 0);
      expect(probe.loaded, isFalse);
      expect(probe.viewMounted, isFalse);
      first.complete();
      await tester.pump();
      expect(probe.viewMounted, isFalse);
      pending.complete();
      await tester.pump();
      expect(probe.viewMounted, isTrue);
      expect(runtime.invalidBuilds, 0);
      expect(probe.identityReuses, 0);
      expect(oldProbe.disposals, 1);
      await tester.pumpWidget(const SizedBox());
      expect(probe.disposedWhileMounted, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$format ignores a load callback after widget disposal', (tester) async {
      final service = ControlledAdService();
      final runtime = ControlledAdRuntime();
      await AdHarness.mount(tester, service, child: child, runtime: runtime);
      final load = native ? service.nativeLoads.single : service.bannerLoads.single;
      final probe = (load.ad as HasAdProbe).probe;
      await tester.pumpWidget(const SizedBox());
      load.complete();
      await tester.pump();
      expect(probe.viewMounted, isFalse);
      expect(probe.disposals, 1);
      expect(runtime.invalidBuilds, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a replacement native identity creates a fresh platform-view subtree', (tester) async {
    final service = ControlledAdService();
    final runtime = ControlledAdRuntime();
    await AdHarness.mount(tester, service, child: const NativeAdWidget(), runtime: runtime);
    final load = service.nativeLoads.single;
    final first = (load.ad as TestNative).probe;
    load.complete();
    await tester.pump();
    final replacement = TestNative();
    load.complete(replacement);
    expect(first.disposals, 0);
    await tester.pump();
    expect(first.viewMounted, isFalse);
    expect(first.disposals, 1);
    expect(first.disposedWhileMounted, 0);
    expect(replacement.probe.viewMounted, isTrue);
    expect(replacement.probe.identityReuses, 0);
    expect(runtime.invalidBuilds, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('obsolete banner sizing cannot create an ad after orientation changes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = ControlledAdService();
    final runtime = ControlledAdRuntime()..deferSizes = true;
    await AdHarness.mount(tester, service, child: const BannerAdWidget(), runtime: runtime);
    expect(runtime.sizes.length, 1);
    tester.view.physicalSize = const Size(600, 800);
    await tester.pump();
    await tester.pump();
    expect(runtime.sizes.length, 2);
    runtime.sizes[0].complete(AdSize.banner);
    await tester.pump();
    expect(service.bannerLoads, isEmpty);
    runtime.sizes[1].complete(AdSize.banner);
    await tester.pump();
    expect(service.bannerLoads.length, 1);
    expect(runtime.invalidBuilds, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
