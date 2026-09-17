import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'mini_bars.dart';

/// Loading / error dock under the generate button. The player itself
/// lives on the flip-card back face.
class StudioStatusDock extends StatelessWidget {
  const StudioStatusDock({
    super.key,
    required this.isDark,
    required this.isLoading,
    required this.error,
    required this.loginRequired,
    required this.onLogin,
    required this.onRetry,
  });

  final bool isDark;
  final bool isLoading;
  final String? error;
  final bool loginRequired;
  final VoidCallback onLogin;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            MiniBars(barCount: 12, height: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Giving your words a Santali voice…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }
    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error ?? 'Something went wrong.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _DockAction(
              label: loginRequired ? 'SIGN IN' : 'RETRY',
              onTap: loginRequired ? onLogin : onRetry,
            ),
          ],
        ),
      ).animate().fadeIn().shake();
    }
    return const SizedBox.shrink();
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
