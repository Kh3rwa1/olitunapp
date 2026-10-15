import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reduce_motion_providers.dart';

/// Propagates the learner's motion preference without overriding OS text size.
class AppExperienceScope extends ConsumerWidget {
  const AppExperienceScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || reduceEffects,
      ),
      child: child,
    );
  }
}
