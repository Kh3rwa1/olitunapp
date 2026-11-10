import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/payments/purchased_categories_provider.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The ad-free listener must not reach the real purchase/auth stack.
  final noPurchases = purchasedCategoriesProvider.overrideWith(
    (ref) async => <String>{},
  );

  ProviderContainer container(SharedPreferences prefs) {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        noPurchases,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('full-screen caps are restored from prefs on a cold start', () async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    SharedPreferences.setMockInitialValues({
      AdStateNotifier.lastAppOpenShownAtKey:
          fiveMinutesAgo.millisecondsSinceEpoch,
      AdStateNotifier.lastInterstitialShownAtKey:
          fiveMinutesAgo.millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();

    final state = container(prefs).read(adStateProvider);
    expect(
      state.lastAppOpenShownAt!.millisecondsSinceEpoch,
      fiveMinutesAgo.millisecondsSinceEpoch,
    );
    expect(
      state.lastInterstitialShownAt!.millisecondsSinceEpoch,
      fiveMinutesAgo.millisecondsSinceEpoch,
    );
    // Even with consent, the 120-minute app open gap still applies.
    expect(state.copyWith(consentAllowsAds: true).canShowAppOpen(), isFalse);
  });

  test('a future timestamp (clock moved back) is ignored', () async {
    SharedPreferences.setMockInitialValues({
      AdStateNotifier.lastAppOpenShownAtKey: DateTime.now()
          .add(const Duration(days: 2))
          .millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(container(prefs).read(adStateProvider).lastAppOpenShownAt, isNull);
  });

  test('showing an interstitial or app open ad persists the time', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = container(prefs);
    expect(c.read(adStateProvider).lastInterstitialShownAt, isNull);

    c.read(adStateProvider.notifier).recordImpression('interstitial', 'quiz');
    c.read(adStateProvider.notifier).recordImpression('app_open');
    c.read(adStateProvider.notifier).recordImpression('rewarded', 'hearts');
    await Future<void>.delayed(Duration.zero);

    final state = c.read(adStateProvider);
    expect(
      prefs.getInt(AdStateNotifier.lastInterstitialShownAtKey),
      state.lastInterstitialShownAt!.millisecondsSinceEpoch,
    );
    expect(
      prefs.getInt(AdStateNotifier.lastAppOpenShownAtKey),
      state.lastAppOpenShownAt!.millisecondsSinceEpoch,
    );
    // Rewarded ads are user-initiated; their cooldown stays in memory.
    expect(prefs.getKeys(), hasLength(2));
  });

  test('works without a prefs provider (caps stay in memory)', () {
    final c = ProviderContainer(overrides: [noPurchases]);
    addTearDown(c.dispose);
    final notifier = c.read(adStateProvider.notifier);
    notifier.recordImpression('app_open');
    expect(c.read(adStateProvider).lastAppOpenShownAt, isNotNull);
  });
}
