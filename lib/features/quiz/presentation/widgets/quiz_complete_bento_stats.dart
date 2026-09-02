import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class QuizCompleteBentoStats extends StatelessWidget {
  const QuizCompleteBentoStats({
    super.key,
    required this.isDark,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.isPassing,
    required this.totalStars,
    required this.bestCombo,
  });

  final bool isDark;
  final int score;
  final int totalQuestions;
  final int percentage;
  final bool isPassing;
  final int totalStars;
  final int bestCombo;

  Widget _buildBentoCard({
    required Widget child,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.25,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Score Bento
        _buildBentoCard(
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          borderColor: AppColors.primary.withValues(alpha: 0.20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score / $totalQuestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.pureBlack,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(),

        // 2. Accuracy Bento
        _buildBentoCard(
          backgroundColor: (isPassing ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.10),
          borderColor: (isPassing ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: isPassing ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                'Accuracy',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isPassing ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms).scale(),

        // 3. Stars Bento
        _buildBentoCard(
          backgroundColor: AppColors.accentGold.withValues(alpha: 0.10),
          borderColor: AppColors.accentGold.withValues(alpha: 0.20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.accentGold,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                'Stars Earned',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+$totalStars',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentGoldDark,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).scale(),

        // 4. Streak Bento
        _buildBentoCard(
          backgroundColor: AppColors.accentOchre.withValues(alpha: 0.10),
          borderColor: AppColors.accentOchre.withValues(alpha: 0.20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accentOchre,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                'Max Combo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$bestCombo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOchreDark,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 350.ms).scale(),
      ],
    );
  }
}
