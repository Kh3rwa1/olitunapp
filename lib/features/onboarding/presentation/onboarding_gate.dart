import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import 'onboarding_screen.dart';
import 'onboarding_v2_screen.dart';

/// Routes `/onboarding` to the multilingual five-step flow when the
/// `onboarding_v2_enabled` flag is on (app_settings collection or the
/// ONBOARDING_V2_ENABLED dart-define). Otherwise keeps the legacy
/// onboarding untouched.
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    if (flags.onboardingV2Enabled) {
      return const OnboardingV2Screen();
    }
    return const OnboardingScreen();
  }
}
