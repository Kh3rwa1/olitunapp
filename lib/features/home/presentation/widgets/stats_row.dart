import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int streak;
  final int stars;
  final int lessons;

  const StatsRow({
    super.key,
    required this.streak,
    required this.stars,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              label: l10n.dayStreak,
              gradient: AppColors.premiumOrange,
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
        const SizedBox(width: 12),
        _StatCard(
              icon: Icons.star_rounded,
              value: '$stars',
              label: l10n.stars,
              gradient: AppColors.premiumGreen,
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
        const SizedBox(width: 12),
        _StatCard(
              icon: Icons.school_rounded,
              value: '$lessons',
              label: l10n.lessons,
              gradient: AppColors.premiumPurple,
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
