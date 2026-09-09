import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, right;
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;
import 'package:mocktail/mocktail.dart' as mocks;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/ads/ad_error.dart';
import 'package:itun/core/ads/ad_service.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/consent_manager.dart';
import 'package:itun/core/ads/widgets/ad_widget_runtime.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/hive_service.dart';

class ControlledConsent extends ConsentManager {
  Future<bool>? pending;

  @override
  Future<bool> canRequestAds() => pending ?? Future<bool>.value(true);
}

class ControlledAdState extends AdStateNotifier {
  ControlledAdState() : super(const AdState(consentAllowsAds: true));

  void allow(bool allowed) => state = state.copyWith(consentAllowsAds: allowed);
}

class TestInterstitial extends mocks.Fake implements InterstitialAd {
  int shows = 0;
  int disposals = 0;
  bool autoDismiss = true;
  Object? showError;

  @override
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  @override
  Future<void> show() async {
    shows++;
    if (showError != null) throw showError!;
    fullScreenContentCallback?.onAdShowedFullScreenContent?.call(this);
    if (autoDismiss) dismiss();
  }

  void dismiss() =>
      fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(this);

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class TestReward extends mocks.Fake implements RewardItem {
  @override
  num get amount => 1;

  @override
  String get type => 'hearts';
}

class TestRewarded extends mocks.Fake implements RewardedAd {
  int shows = 0;
  int disposals = 0;
  bool autoDismiss = true;
  bool autoEarn = true;
  bool callbacksBeforeError = false;
  Object? showError;
  void Function(AdWithoutView, RewardItem)? rewardCallback;

  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  @override
  Future<void> show({
    required void Function(AdWithoutView, RewardItem) onUserEarnedReward,
  }) async {
    shows++;
    rewardCallback = onUserEarnedReward;
    if (showError != null && !callbacksBeforeError) throw showError!;
    fullScreenContentCallback?.onAdShowedFullScreenContent?.call(this);
    if (autoEarn) earn();
    if (autoDismiss) dismiss();
    if (showError != null) throw showError!;
  }

  void earn() => rewardCallback?.call(this, TestReward());

  void dismiss() =>
      fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(this);

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class AdProbe {
  bool loaded = false;
  bool viewMounted = false;
  int disposals = 0;
  int disposedWhileMounted = 0;
  int identityReuses = 0;

  void release() {
    if (viewMounted) disposedWhileMounted++;
    disposals++;
  }
}

abstract interface class HasAdProbe {
  AdProbe get probe;
}

class TestNative extends mocks.Fake implements NativeAd, HasAdProbe {
  @override
  final AdProbe probe = AdProbe();

  @override
  Future<void> dispose() async => probe.release();
}

class TestBanner extends mocks.Fake implements BannerAd, HasAdProbe {
  @override
  final AdProbe probe = AdProbe();

  @override
  AdSize get size => AdSize.banner;

  @override
  Future<void> dispose() async => probe.release();
}

class EmbeddedLoad<T extends AdWithView> {
  final T ad;
  final void Function(Ad) loaded;
  final void Function(Ad, LoadAdError) failed;

  EmbeddedLoad(this.ad, this.loaded, this.failed);

  void complete([T? replacement]) {
    final result = replacement ?? ad;
    (result as HasAdProbe).probe.loaded = true;
    loaded(result);
  }
}

class ControlledAdService extends AdService {
  ControlledAdService({super.trackedAds}) : super.forTesting();

  final ControlledConsent consent = ControlledConsent();
  final Set<Ad> claimed = {};
  final interstitialLoads = <Completer<Either<AdError, InterstitialAd>>>[];
  final rewardedLoads = <Completer<Either<AdError, RewardedAd>>>[];
  final nativeLoads = <EmbeddedLoad<NativeAd>>[];
  final bannerLoads = <EmbeddedLoad<BannerAd>>[];
  TestNative? firstNative;
  TestBanner? firstBanner;

  @override
  ConsentManager get consentManager => consent;

  @override
  void takeOwnership(Ad ad) {
    claimed.add(ad);
    super.takeOwnership(ad);
  }

  @override
  Future<Either<AdError, InterstitialAd>> loadInterstitialAd({
    bool enableFallback = true,
  }) {
    final pending = Completer<Either<AdError, InterstitialAd>>();
    interstitialLoads.add(pending);
    return pending.future;
  }

  @override
  Future<Either<AdError, RewardedAd>> loadRewardedAd({
    bool enableFallback = true,
  }) {
    final pending = Completer<Either<AdError, RewardedAd>>();
    rewardedLoads.add(pending);
    return pending.future;
  }

  void completeInterstitial(int index, TestInterstitial ad) =>
      interstitialLoads[index].complete(right<AdError, InterstitialAd>(ad));

  void completeRewarded(int index, TestRewarded ad) =>
      rewardedLoads[index].complete(right<AdError, RewardedAd>(ad));

  @override
  NativeAd? createNativeAd({
    String? factoryId,
    NativeTemplateStyle? nativeTemplateStyle,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
    void Function(Ad)? onOpened,
    void Function(Ad)? onClosed,
    void Function(Ad)? onImpression,
    void Function(Ad)? onClicked,
    bool enableFallback = true,
  }) {
    final ad = nativeLoads.isEmpty ? firstNative ?? TestNative() : TestNative();
    nativeLoads.add(EmbeddedLoad(ad, onLoaded, onFailed));
    return ad;
  }

  @override
  BannerAd? createBannerAd({
    required AdSize size,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
    void Function(Ad)? onOpened,
    void Function(Ad)? onClosed,
    void Function(Ad)? onImpression,
    void Function(Ad)? onClicked,
    bool enableFallback = true,
  }) {
    final ad = bannerLoads.isEmpty ? firstBanner ?? TestBanner() : TestBanner();
    bannerLoads.add(EmbeddedLoad(ad, onLoaded, onFailed));
    return ad;
  }
}

class ControlledAdRuntime extends AdWidgetRuntime {
  bool deferSizes = false;
  int invalidBuilds = 0;
  final sizes = <Completer<AdSize>>[];

  @override
  bool get isSupported => true;

  @override
  Future<AdSize> adaptiveBannerSize(int width) {
    final size = Completer<AdSize>();
    sizes.add(size);
    if (!deferSizes) size.complete(AdSize.banner);
    return size.future;
  }

  @override
  Widget buildAd(AdWithView ad) {
    final probe = (ad as HasAdProbe).probe;
    if (!probe.loaded || probe.disposals != 0) invalidBuilds++;
    return _ProbeView(probe);
  }
}

class _ProbeView extends StatefulWidget {
  final AdProbe probe;
  const _ProbeView(this.probe);

  @override
  State<_ProbeView> createState() => _ProbeViewState();
}

class _ProbeViewState extends State<_ProbeView> {
  @override
  void initState() {
    super.initState();
    widget.probe.viewMounted = true;
  }

  @override
  void didUpdateWidget(_ProbeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.probe, widget.probe)) {
      oldWidget.probe.viewMounted = false;
      widget.probe.viewMounted = true;
      widget.probe.identityReuses++;
    }
  }

  @override
  void dispose() {
    widget.probe.viewMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}

class AdHarness {
  final ProviderContainer container;
  final ControlledAdService service;
  final ControlledAdState state;
  final BuildContext context;
  bool _closed = false;

  AdHarness(this.container, this.service, this.state, this.context);

  void close() {
    if (_closed) return;
    _closed = true;
    container.dispose();
    service.dispose();
  }

  static Future<AdHarness> mount(
    WidgetTester tester,
    ControlledAdService service, {
    Widget child = const SizedBox(),
    ControlledAdRuntime? runtime,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = ControlledAdState();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        adServiceProvider.overrideWithValue(service),
        // Keep ad lifecycle tests isolated from account/network analytics timers.
        learningAnalyticsServiceProvider.overrideWithValue(
          LearningAnalyticsService(
            prefs: prefs,
            remoteWriter: (eventId, payload) async {},
          ),
        ),
        adStateProvider.overrideWith(() => state),
        connectivityStreamProvider.overrideWith(
          (ref) => const Stream<List<ConnectivityResult>>.empty(),
        ),
        if (runtime != null) adWidgetRuntimeProvider.overrideWithValue(runtime),
      ],
    );
    late BuildContext context;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return Scaffold(body: child);
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final harness = AdHarness(container, service, state, context);
    addTearDown(harness.close);
    return harness;
  }
}
