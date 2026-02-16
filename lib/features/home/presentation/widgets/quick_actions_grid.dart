import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/scale_button.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  final bool isDark;

  const QuickActionsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.quiz_rounded,
            label: l10n.dailyQuiz,
            gradient: AppColors.premiumPink,
            onTap: () => context.go('/quizzes'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.text_fields_rounded,
            label: l10n.practice,
            gradient: AppColors.premiumMint,
            onTap: () => context.go('/lessons/category/alphabets'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(
                alpha: 0.3,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
