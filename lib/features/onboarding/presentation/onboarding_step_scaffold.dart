import 'package:flutter/material.dart';

import 'onboarding_ambient.dart';

/// Shared step layout for the onboarding flow: locale-neutral step
/// eyebrow ("01 · 05"), display title, optional subtitle, and content.
///
/// Extracted from `onboarding_v2_screen.dart` to keep that file under
/// the length gate.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.isDark,
    required this.child,
    required this.step,
    required this.stepCount,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool isDark;
  final Widget child;
  final int step;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingEyebrow(step: step, stepCount: stepCount, isDark: isDark),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
