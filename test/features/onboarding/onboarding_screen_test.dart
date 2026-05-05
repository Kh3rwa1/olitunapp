// Screen-level pump test for the onboarding flow.
//
// We can't realistically pump the full OnboardingScreen widget here —
// it depends on a video controller, GoRouter, AppColors gradients, and
// a Riverpod graph rooted in `prefs` (SharedPreferences) — but we CAN
// verify the StateNotifier that drives it, which is the actual contract
// other layers depend on.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart' as hive_service;
import 'package:itun/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hive_service.prefs = await SharedPreferences.getInstance();
  });

  test('OnboardingNotifier initial state is true (show onboarding)', () {
    final notifier = OnboardingNotifier();
    expect(notifier.state, isTrue);
  });

  test(
    'completeOnboarding flips state to false and persists the flag',
    () async {
      final notifier = OnboardingNotifier();
      await notifier.completeOnboarding();
      expect(notifier.state, isFalse);
      expect(hive_service.prefs.getBool('show_onboarding'), isFalse);
    },
  );

  test(
    'after completing onboarding, a new notifier reads false from prefs',
    () async {
      SharedPreferences.setMockInitialValues({'show_onboarding': false});
      hive_service.prefs = await SharedPreferences.getInstance();
      final notifier = OnboardingNotifier();
      expect(
        notifier.state,
        isFalse,
        reason: 'persisted "false" flag must short-circuit onboarding',
      );
    },
  );
}
