import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((
  ref,
) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(_checkOnboardingStatus());

  static bool _checkOnboardingStatus() {
    return prefs.getBool('show_onboarding') ?? true;
  }

  Future<void> completeOnboarding() async {
    await prefs.setBool('show_onboarding', false);
    state = false;
  }
}
