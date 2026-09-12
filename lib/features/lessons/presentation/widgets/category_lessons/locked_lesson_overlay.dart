import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Playful full-screen takeover for locked lessons: an oversized peeking
/// Eyes animation, big friendly typography, and a direct CTA into the
/// blocking lesson. Replaces the easily-missed snackbar.
///
/// Copy stays hardcoded English like the rest of the lock flow
/// (`_LockedLessonView`), so no locale additions are required.
class LockedLessonOverlay extends StatelessWidget {
  const LockedLessonOverlay({
    super.key,
    required this.blockingLessonTitle,
    required this.onStartBlockingLesson,
    required this.isDark,
  });

  /// Null-safe display name of the lesson blocking progress.
  final String? blockingLessonTitle;
  final VoidCallback onStartBlockingLesson;
  final bool isDark;

  static Future<void> show(
    BuildContext context, {
    required String? blockingLessonTitle,
    required VoidCallback onStartBlockingLesson,
    required bool isDark,
  }) {
    // showDialog already opens on the root navigator, above the shell.
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: LockedLessonOverlay(
          blockingLessonTitle: blockingLessonTitle,
          onStartBlockingLesson: () {
            Navigator.of(dialogContext).pop();
            onStartBlockingLesson();
          },
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = RespectMotion.of(context);
    final blocker = (blockingLessonTitle?.isNotEmpty ?? false)
        ? blockingLessonTitle!
        : 'the previous lesson';
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Semantics(
      label: 'Lesson locked. Complete $blocker first to unlock this lesson.',
      child: SpringPop(
        trigger: blocker,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.nightElevated, AppColors.nightPanel],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Oversized peeking eyes spill past the card edges.
              SizedBox(
                height: 190,
                child: OverflowBox(
                  maxWidth: screenWidth,
                  maxHeight: 260,
                  child: Lottie.asset(
                    'assets/animations/eyes_overlay.json',
                    width: screenWidth,
                    fit: BoxFit.cover,
                    animate: !reduceMotion,
                    repeat: !reduceMotion,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.lock_rounded,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HOLD ON • LOCKED FOR NOW',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This one’s still winking at you',
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Complete “$blocker” first to crack it open.',
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('locked-overlay-start'),
                        // Wrapper in [show] dismisses before navigating.
                        onPressed: onStartBlockingLesson,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Take me there'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Back to learning path',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
