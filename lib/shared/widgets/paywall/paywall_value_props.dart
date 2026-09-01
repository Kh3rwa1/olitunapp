import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PaywallValueProps extends StatelessWidget {
  final bool isDark;

  const PaywallValueProps({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildValuePropRow(
          context,
          icon: Icons.offline_pin_rounded,
          title: 'Full Offline Pack Access',
          subtitle:
              'Download lessons, audio pronunciations, and quizzes for anytime offline learning.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildValuePropRow(
          context,
          icon: Icons.translate_rounded,
          title: 'Unlimited AI Translations',
          subtitle:
              'Instant Ol Chiki translations and pronunciation guides without query limits.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildValuePropRow(
          context,
          icon: Icons.block_flipped,
          title: 'Zero Ad Interruptions',
          subtitle:
              'Experience 100% distraction-free language practice across all modules.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildValuePropRow(
          context,
          icon: Icons.all_inclusive_rounded,
          title: 'Lifetime Access Guarantee',
          subtitle:
              'Pay once with no recurring fees, subscriptions, or hidden charges.',
        ),
      ],
    );
  }

  Widget _buildValuePropRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
