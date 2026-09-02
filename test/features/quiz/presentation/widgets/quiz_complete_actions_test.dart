import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/ads/interstitial_ad_manager.dart';
import 'package:itun/core/ads/rewarded_ad_manager.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_actions.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

/// Records the reward callback and lets each test decide whether the ad
/// "played" — no real google_mobile_ads is ever touched.
class _FakeRewardedAdManager implements RewardedAdManager {
  bool shouldGrantReward = false;

  bool rewardGranted = false;
  int? grantedAmount;

  @override
  Future<bool> show({
    required BuildContext context,
    required String placement,
    required RewardType rewardType,
    required int amount,
    required FutureOr<void> Function() onRewardGranted,
  }) async {
    if (!shouldGrantReward) return false;
    rewardGranted = true;
    grantedAmount = amount;
    await onRewardGranted();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeInterstitialAdManager implements InterstitialAdManager {
  int showCalls = 0;

  @override
  Future<bool> showIfAllowed(BuildContext context, String trigger) async {
    showCalls++;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _host({required List<Override> overrides}) {
  final router = GoRouter(
    initialLocation: '/quiz-done',
    routes: [
      GoRoute(
        path: '/quiz-done',
        builder: (context, state) => const Scaffold(
          body: QuizCompleteActions(
            isPassing: true,
            score: 3,
            totalQuestions: 3,
            percentage: 100,
            totalStars: 25,
          ),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Center(child: Text('Home Screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  late _FakeRewardedAdManager rewarded;
  late _FakeInterstitialAdManager interstitial;

  setUp(() {
    rewarded = _FakeRewardedAdManager();
    interstitial = _FakeInterstitialAdManager();
  });

  List<Override> overrides() => [
    rewardedAdManagerProvider.overrideWithValue(rewarded),
    interstitialAdManagerProvider.overrideWithValue(interstitial),
  ];

  testWidgets('renders bonus-stars, share and continue actions', (
    tester,
  ) async {
    await tester.pumpWidget(_host(overrides: overrides()));
    await tester.pumpAndSettle();

    expect(find.text('Watch Ad for +50 Bonus Stars'), findsOneWidget);
    // Passing score also surfaces the share achievement affordance.
    expect(find.text('Share Achievement'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets(
    'bonus-stars tap grants 50 stars without an ad for ad-free users',
    (tester) async {
      rewarded.shouldGrantReward = true;
      await tester.pumpWidget(_host(overrides: overrides()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Watch Ad for +50 Bonus Stars'));
      await tester.pumpAndSettle();

      expect(rewarded.rewardGranted, isTrue);
      expect(rewarded.grantedAmount, 50);
      expect(find.textContaining('Bonus 50 Stars Earned'), findsOneWidget);
    },
  );

  testWidgets('bonus-stars tap shows the cooldown snackbar when no ad plays', (
    tester,
  ) async {
    rewarded.shouldGrantReward = false;
    await tester.pumpWidget(_host(overrides: overrides()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Watch Ad for +50 Bonus Stars'));
    await tester.pumpAndSettle();

    expect(rewarded.rewardGranted, isFalse);
    expect(find.textContaining('cooling down'), findsOneWidget);
  });

  testWidgets('continue routes home after asking for an interstitial', (
    tester,
  ) async {
    await tester.pumpWidget(_host(overrides: overrides()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
    expect(interstitial.showCalls, 1);
  });
}
