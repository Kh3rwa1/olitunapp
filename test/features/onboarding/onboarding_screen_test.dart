// Screen-level pump test for the onboarding flow.
//
// We can't realistically pump the full OnboardingScreen widget here —
// it depends on a video controller, GoRouter, AppColors gradients, and
// a Riverpod graph rooted in SharedPreferences — but we CAN verify the
// StateNotifier that drives it, which is the actual contract other
// layers depend on.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  test('OnboardingNotifier initial state is true (show onboarding)', () {
    final notifier = container.read(onboardingProvider.notifier);
    expect(notifier.state, isTrue);
  });

  test(
    'completeOnboarding flips state to false and persists the flag',
    () async {
      final notifier = container.read(onboardingProvider.notifier);
      await notifier.completeOnboarding();
      expect(notifier.state, isFalse);
      expect(
        container.read(sharedPreferencesProvider).getBool('show_onboarding'),
        isFalse,
      );
    },
  );

  test(
    'after completing onboarding, a new notifier reads false from prefs',
    () async {
      SharedPreferences.setMockInitialValues({'show_onboarding': false});
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c2.dispose);

      final notifier = c2.read(onboardingProvider.notifier);
      expect(
        notifier.state,
        isFalse,
        reason: 'persisted "false" flag must short-circuit onboarding',
      );
    },
  );
}
