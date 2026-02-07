import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final streak = ref.watch(userStreakProvider);
    final stars = ref.watch(userStarsProvider);
    // ignore: unused_local_variable
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final quizzesCompleted = ref.watch(quizzesCompletedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Learning Journey',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        'Keep up the great work, $userName!',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ResponsivePageContainer(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Core Stats Row
                  isTablet
                      ? Row(
                          children: [
                            Expanded(
                              child: _AnalyticsMetricCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '$streak',
                                label: 'Day Streak',
                                color: AppColors.duoOrange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _AnalyticsMetricCard(
                                icon: Icons.star_rounded,
                                value: '$stars',
                                label: 'Stars Earned',
                                color: AppColors.duoYellow,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _AnalyticsMetricCard(
                                icon: Icons.quiz_rounded,
                                value: '$quizzesCompleted',
                                label: 'Quiz Done',
                                color: AppColors.duoBlue,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _AnalyticsMetricCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '$streak',
                                label: 'Day Streak',
                                color: AppColors.duoOrange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _AnalyticsMetricCard(
                                icon: Icons.star_rounded,
                                value: '$stars',
                                label: 'Stars Earned',
                                color: AppColors.duoYellow,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // Skills Breakdown
                  _buildSectionHeader('SKILLS MASTERY', isDark),
                  const SizedBox(height: 16),
                  _buildSkillsGrid(context, isDark, isTablet),
                  const SizedBox(height: 40),

                  // Accuracy / Quizzes
                  _buildSectionHeader('QUIZ ANALYSIS', isDark),
                  const SizedBox(height: 16),
                  _QuizPerformanceCard(
                    quizzes: quizzesCompleted,
                    accuracy: 88, // Placeholder for real data calculation
                    isDark: isDark,
                  ),
                  const SizedBox(height: 40),

                  // Settings & Profile
                  _buildSectionHeader('ACCOUNT', isDark),
                  const SizedBox(height: 12),
                  _buildActionTiles(context, ref, isDark),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDark ? AppColors.primary : AppColors.primaryDark,
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSkillsGrid(BuildContext context, bool isDark, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _SkillProgressCard(
            label: 'Alphabet',
            progress: 0.8,
            color: AppColors.duoBlue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SkillProgressCard(
            label: 'Numbers',
            progress: 0.45,
            color: AppColors.duoOrange,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SkillProgressCard(
            label: 'Vocabulary',
            progress: 0.15,
            color: AppColors.duoGreen,
            isDark: isDark,
          ),
        ),
        if (isTablet) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _SkillProgressCard(
              label: 'Rhymes',
              progress: 0.66,
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionTiles(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        _ModernActionTile(
          icon: Icons.edit_rounded,
          label: 'Edit Profile Name',
          isDark: isDark,
          onTap: () {},
        ),
        _ModernActionTile(
          icon: Icons.settings_rounded,
          label: 'App Settings',
          isDark: isDark,
          onTap: () => context.go('/settings'),
        ),
      ],
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _AnalyticsMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glass(context, opacity: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glass(context, opacity: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }
}

class _SkillProgressCard extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final bool isDark;

  const _SkillProgressCard({
    required this.label,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.glass(context, opacity: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glass(context, opacity: 0.06)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuizPerformanceCard extends StatelessWidget {
  final int quizzes;
  final int accuracy;
  final bool isDark;

  const _QuizPerformanceCard({
    required this.quizzes,
    required this.accuracy,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.duoPurple, AppColors.duoPurpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.duoPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assessment Score',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$accuracy%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      'Accuracy',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$quizzes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Quizzes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.white12),
            ],
          ),
        ),
      ),
    );
  }
}
