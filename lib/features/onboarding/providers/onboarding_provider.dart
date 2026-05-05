import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((
  ref,
) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(_initialCheck(_ref));

  static bool _initialCheck(Ref ref) {
    return ref.read(sharedPreferencesProvider).getBool('show_onboarding') ??
        true;
  }

  Future<void> completeOnboarding() async {
    await _ref
        .read(sharedPreferencesProvider)
        .setBool('show_onboarding', false);
    state = false;
  }
}
