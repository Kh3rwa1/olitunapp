import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/ads/interstitial_ad_manager.dart';
import 'package:itun/core/theme/app_colors.dart';

/// Floating circular icon button with blur effect.
class LessonBlockFloatingButton extends StatelessWidget {
  const LessonBlockFloatingButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            tooltip: tooltip,
            onPressed: onPressed,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }
}

/// Top navigation bar with animated step progress, back button, and audio action button.
class LessonBlockTopNavBar extends ConsumerWidget {
  const LessonBlockTopNavBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.accentColor,
    required this.isDark,
    required this.hasAudio,
    this.onAudioPressed,
    this.audioKey,
    this.onBackPressed,
    this.backIcon,
  });

  final int totalSteps;
  final int currentStep;
  final Color accentColor;
  final bool isDark;
  final bool hasAudio;
  final VoidCallback? onAudioPressed;
  final ValueKey<String>? audioKey;
  final VoidCallback? onBackPressed;
  final IconData? backIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (totalSteps > 0) ? (currentStep + 1) / totalSteps : 0.0;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 780 : double.infinity,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 8,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.webBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              LessonBlockFloatingButton(
                icon: backIcon ?? Icons.arrow_back_rounded,
                tooltip: 'Go back',
                onPressed:
                    onBackPressed ??
                    () async {
                      await ref
                          .read(interstitialAdManagerProvider)
                          .showIfAllowed(context, 'lesson_complete');
                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      }
                    },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'STEP ${currentStep + 1} OF $totalSteps',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white60 : AppColors.webSlate,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: constraints.maxWidth * progress,
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withValues(alpha: 0.75),
                                    accentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 44,
                height: 44,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: hasAudio && onAudioPressed != null
                      ? LessonBlockFloatingButton(
                          key: audioKey,
                          icon: Icons.volume_up_rounded,
                          tooltip: 'Play audio (Space)',
                          onPressed: onAudioPressed!,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
