import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/quiz_session_notifier.dart';

/// Progress pill showing `current/total` in the quiz app bar.
class QuizCountPill extends StatelessWidget {
  const QuizCountPill({
    super.key,required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quiz progress',
      value: 'Question $current of $total',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$current/$total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hearts / combo / multiplier HUD shown above the question.
class QuizSessionHud extends StatelessWidget {
  const QuizSessionHud({
    super.key,required this.state, required this.isDark});

  final QuizSessionState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final showCombo = state.comboStreak > 0;

    return Semantics(
      container: true,
      label: 'Quiz session stats',
      value: showCombo
          ? '${state.hearts} hearts, ${state.comboStreak} answer combo, ${state.comboMultiplier} times multiplier'
          : '${state.hearts} hearts',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: _HudChip(
                icon: Icons.favorite_rounded,
                label: '${state.hearts}',
                accent: AppColors.accentTerracotta,
                isDark: isDark,
              ),
            ),
            if (showCombo) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _HudChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${state.comboStreak}',
                  accent: AppColors.accentOchre,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudChip(
                  icon: Icons.bolt_rounded,
                  label: 'x${state.comboMultiplier}',
                  accent: AppColors.accentGold,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
