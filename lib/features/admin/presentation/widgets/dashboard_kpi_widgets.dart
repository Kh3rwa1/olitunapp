import 'package:flutter/material.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// Hero metric card showing total content count with gradient background.
class DashboardHeroMetric extends StatelessWidget {
  final bool isDark;
  final int total;
  final bool isLoading;
  final double? weekDelta;
  const DashboardHeroMetric({super.key, required this.isDark, required this.total, required this.isLoading, this.weekDelta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark ? [const Color(0xFF0E1A14), const Color(0xFF0A0F0C)] : [const Color(0xFFE8FFF3), const Color(0xFFFAFFFC)],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10), blurRadius: 40, offset: const Offset(0, 18), spreadRadius: -10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 6, color: AppColors.primary),
            SizedBox(width: 6),
            Text('TOTAL CONTENT', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 18),
        Text(isLoading ? '—' : total.toString(), style: AdminTokens.display(isDark).copyWith(fontSize: 64, height: 1, letterSpacing: -2)),
        const SizedBox(height: 6),
        Text('Published units across the curriculum', style: AdminTokens.body(isDark).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        Row(children: [
          if (weekDelta != null) ...[
            _pill(isDark, weekDelta! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              '${weekDelta! >= 0 ? '+' : ''}${weekDelta!.toStringAsFixed(0)}% wk',
              weekDelta! >= 0 ? AppColors.primary : AppColors.duoOrange),
            const SizedBox(width: 8),
          ],
          _pill(isDark, Icons.history_rounded, 'Updated just now', null),
        ]),
      ]),
    );
  }

  Widget _pill(bool isDark, IconData icon, String label, Color? color) {
    final c = color ?? AdminTokens.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.2)),
      ]),
    );
  }
}

/// Small KPI card for categories/lessons/vocabulary/quizzes/etc.
class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool isDark;
  const DashboardKpiCard({super.key, required this.label, required this.value, required this.icon, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label.toUpperCase(), style: AdminTokens.eyebrow(isDark).copyWith(fontSize: 10.5)),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AdminTokens.metric(isDark)),
          const SizedBox(height: 4),
          Text('Active items', style: AdminTokens.label(isDark).copyWith(color: AdminTokens.textTertiary(isDark), fontSize: 11, letterSpacing: 0.2, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
