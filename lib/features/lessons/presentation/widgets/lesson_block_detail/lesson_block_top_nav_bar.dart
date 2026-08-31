import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/ads/interstitial_ad_manager.dart';

/// Floating circular icon button with blur effect.
class LessonBlockFloatingButton extends StatelessWidget {
  const LessonBlockFloatingButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          LessonBlockFloatingButton(
            icon: backIcon ?? Icons.arrow_back_rounded,
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
          const SizedBox(width: 16),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.7),
                            accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 44,
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasAudio && onAudioPressed != null
                  ? LessonBlockFloatingButton(
                      key: audioKey,
                      icon: Icons.volume_up_rounded,
                      onPressed: onAudioPressed!,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
