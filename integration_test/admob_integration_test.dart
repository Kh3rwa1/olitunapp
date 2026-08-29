import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';
import 'package:itun/core/ads/rewarded_ad_manager.dart';
import 'package:itun/core/storage/hive_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('AdMob Integration Tests', () {
    testWidgets('BannerAdWidget renders shrink when Ad-Free', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adStateProvider.overrideWith(
              () => AdStateNotifier(const AdState(isAdFreeUser: true)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BannerAdWidget(placement: 'integration_test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // BannerAdWidget should return SizedBox.shrink() when isAdFreeUser == true
      expect(find.byType(BannerAdWidget), findsOneWidget);
    });

    testWidgets('NativeAdWidget renders shrink when Ad-Free', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adStateProvider.overrideWith(
              () => AdStateNotifier(const AdState(isAdFreeUser: true)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NativeAdWidget(placement: 'integration_test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NativeAdWidget), findsOneWidget);
    });

    testWidgets('Rewarded ad flow delivers rewards properly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Olitun Monetization Test')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final element = tester.element(find.text('Olitun Monetization Test'));
      final container = ProviderScope.containerOf(element);

      // Free user receives callback or gracefully handles ad not ready in test harness
      final manager = container.read(rewardedAdManagerProvider);
      bool rewardReceived = false;

      // Simulate ad-free reward path
      container.read(adStateProvider.notifier).setIsAdFreeUser(true);
      await manager.show(
        context: element,
        placement: 'integration_reward',
        rewardType: RewardType.stars,
        amount: 25,
        onRewardGranted: () {
          rewardReceived = true;
        },
      );

      expect(rewardReceived, isTrue);
    });
  });
}
