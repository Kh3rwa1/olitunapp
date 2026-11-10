import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/app_open_tracker.dart';
import '../update/update_gate.dart';
import 'reduce_motion_providers.dart';

/// Root scope under MaterialApp.router's builder: propagates the learner's
/// motion preference without overriding OS text size, keeps the app-open
/// tracker alive, and stops builds below the minimum supported build.
class AppExperienceScope extends ConsumerWidget {
  const AppExperienceScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    // Lifecycle analytics (`app_open`) live for the app's lifetime; null in
    // headless tests without prefs.
    ref.watch(appOpenTrackerProvider);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || reduceEffects,
      ),
      child: UpdateGate(child: child),
    );
  }
}
