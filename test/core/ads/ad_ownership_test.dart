import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:itun/core/ads/ad_service.dart';

class _TrackedAd extends Fake implements Ad {
  int disposals = 0;
  bool failDispose = false;

  @override
  Future<void> dispose() async {
    disposals++;
    if (failDispose) throw StateError('synthetic SDK cleanup failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'memory pressure cannot invalidate a claimed widget or manager ad',
    () async {
      final ad = _TrackedAd();
      final service = AdService.forTesting(trackedAds: [ad]);
      addTearDown(service.dispose);

      service.takeOwnership(ad);
      service.didHaveMemoryPressure();
      await Future<void>.value();
      expect(ad.disposals, 0);

      service.releaseAd(ad);
      await Future<void>.value();
      expect(ad.disposals, 1);
      service.disposeAll();
      await Future<void>.value();
      expect(ad.disposals, 1);
    },
  );

  test('unclaimed ads are still released under memory pressure', () async {
    final owned = _TrackedAd();
    final unclaimed = _TrackedAd();
    final service = AdService.forTesting(trackedAds: [owned, unclaimed]);
    addTearDown(service.dispose);
    service.takeOwnership(owned);

    service.didHaveMemoryPressure();
    await Future<void>.value();
    expect(unclaimed.disposals, 1);
    expect(owned.disposals, 0);
    service.releaseAd(owned);
    await Future<void>.value();
  });

  test(
    'duplicate releases are idempotent even when SDK disposal fails asynchronously',
    () async {
      final ad = _TrackedAd()..failDispose = true;
      final service = AdService.forTesting(trackedAds: [ad]);
      addTearDown(service.dispose);
      service.releaseAd(ad);
      service.releaseAd(ad);
      service.disposeAll();
      await Future<void>.value();
      expect(ad.disposals, 1);
    },
  );
}
