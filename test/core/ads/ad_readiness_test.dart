import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/ad_service.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/consent_manager.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:mocktail/mocktail.dart';

class _AdService extends Fake implements AdService {
  @override
  final ConsentManager consentManager = ConsentManager();

  @override
  final ValueNotifier<bool> readiness = ValueNotifier(false);

  @override
  bool get canServeAds => readiness.value && consentManager.requestsAllowed;
}

void main() {
  test('consent before SDK readiness cannot enable ads', () async {
    final service = _AdService();
    final container = ProviderContainer(
      overrides: [
        adServiceProvider.overrideWithValue(service),
        purchasedCategoriesProvider.overrideWith((ref) async => <String>{}),
      ],
    );
    addTearDown(() {
      container.dispose();
      service.readiness.dispose();
      service.consentManager.adsAllowed.dispose();
    });
    expect(container.read(adStateProvider).shouldShowAds, isFalse);
    service.consentManager.adsAllowed.value = true;
    expect(container.read(adStateProvider).shouldShowAds, isFalse);
    service.readiness.value = true;
    expect(container.read(adStateProvider).shouldShowAds, isTrue);
    service.consentManager.adsAllowed.value = false;
    expect(container.read(adStateProvider).shouldShowAds, isFalse);
  });

  test('SDK readiness without consent remains fail closed', () async {
    final service = _AdService();
    final container = ProviderContainer(
      overrides: [
        adServiceProvider.overrideWithValue(service),
        purchasedCategoriesProvider.overrideWith((ref) async => <String>{}),
      ],
    );
    addTearDown(() {
      container.dispose();
      service.readiness.dispose();
      service.consentManager.adsAllowed.dispose();
    });
    expect(container.read(adStateProvider).shouldShowAds, isFalse);
    service.readiness.value = true;
    expect(container.read(adStateProvider).shouldShowAds, isFalse);
  });
}
