import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool('show_onboarding') ??
        true;
  }

  Future<void> completeOnboarding() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool('show_onboarding', false);
  }
}
