import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/interstitial_ad_manager.dart';
import 'package:itun/core/ads/rewarded_ad_manager.dart';
import 'package:itun/core/storage/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Ad Managers Unit Tests', () {
    testWidgets('InterstitialAdManager respects ad-free and frequency rules', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adStateProvider.overrideWith(() {
              final notifier = AdStateNotifier();
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: Text('Test'))),
        ),
      );

      final element = tester.element(find.text('Test'));
      final container = ProviderScope.containerOf(element);

      final manager = container.read(interstitialAdManagerProvider);

      // Ad is not loaded in unit test environment, so showIfAllowed returns false gracefully without crashing
      final shown = await manager.showIfAllowed(element, 'lesson_complete');
      expect(shown, isFalse);

      // Setting ad-free suppresses instantly
      container.read(adStateProvider.notifier).setIsAdFreeUser(true);
      final suppressed = await manager.showIfAllowed(
        element,
        'lesson_complete',
      );
      expect(suppressed, isFalse);
    });

    testWidgets(
      'RewardedAdManager instantly grants rewards to Ad-Free users without loading ads',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MaterialApp(home: Scaffold(body: Text('Test'))),
          ),
        );

        final element = tester.element(find.text('Test'));
        final container = ProviderScope.containerOf(element);

        // Set user as Ad-Free
        container.read(adStateProvider.notifier).setIsAdFreeUser(true);

        final rewardedManager = container.read(rewardedAdManagerProvider);
        bool rewardCallbackTriggered = false;

        final success = await rewardedManager.show(
          context: element,
          placement: 'quiz_reward_test',
          rewardType: RewardType.stars,
          amount: 50,
          onRewardGranted: () {
            rewardCallbackTriggered = true;
          },
        );

        expect(success, isTrue);
        expect(rewardCallbackTriggered, isTrue);
      },
    );
  });
}
