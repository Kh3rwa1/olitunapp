import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// Selectable option card used by the onboarding flow.
///
/// Carries its own Semantics (button + selected state), a 52dp minimum
/// touch target, and an animated selected state. Extracted from
/// `onboarding_v2_screen.dart` to keep that file under the length gate.
///
/// [index] staggers the mount entrance (fade + rise, 60ms apart). The
/// entrance plays once per element mount; selection toggles only animate
/// the decoration, so re-taps never replay the entrance.
class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.index = 0,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
          button: true,
          selected: selected,
          label: title,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.28 : 0.14,
                            ),
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.10 : 0.04,
                            ),
                          ],
                        )
                      : null,
                  color: selected
                      ? null
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06)),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.25 : 0.18,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? AppColors.primary
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ).animate().scale(
                        begin: const Offset(0.4, 0.4),
                        duration: 220.ms,
                        curve: Curves.easeOutBack,
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 380.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          delay: (60 * index).ms,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
