import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

// ═══════════════ DATA CLASSES ═══════════════

class StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int? numericValue;
  final String suffix;
  const StatData(this.icon, this.value, this.label, this.color)
    : numericValue = null,
      suffix = '';
  const StatData.counter(
    this.icon,
    int value,
    this.label,
    this.color, {
    this.suffix = '',
  }) : numericValue = value,
       value = '';
}

class SkillData {
  final String label;
  final double progress;
  final Color color;
  const SkillData(this.label, this.progress, this.color);
}

// ═══════════════ STATS GRID ═══════════════

class StatsGrid extends StatelessWidget {
  final int streak;
  final int stars;
  final int quizzesCompleted;
  final int learningTime;
  final bool isDark;
  final bool isTablet;

  const StatsGrid({
    super.key,
    required this.streak,
    required this.stars,
    required this.quizzesCompleted,
    required this.learningTime,
    required this.isDark,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero stat — streak spans full width
        AnimatedBentoChild(
          index: 0,
          child: BentoCell(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                AppColors.duoOrange.withValues(alpha: isDark ? 0.15 : 0.08),
                AppColors.duoOrange.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
            ),
            border: Border.all(
              color: AppColors.duoOrange.withValues(alpha: isDark ? 0.2 : 0.12),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.duoOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.duoOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedCounter(
                      value: streak,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'DAY STREAK',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.duoOrange,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.duoOrange.withValues(alpha: 0.4),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 3 stat pills in a row
        Row(
          children: [
            Expanded(
              child: AnimatedBentoChild(
                index: 1,
                child: StatPill(
                  data: StatData.counter(
                    Icons.star_rounded,
                    stars,
                    'Stars',
                    AppColors.duoYellow,
                  ),
                  isDark: isDark,
                  delay: 80,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBentoChild(
                index: 2,
                child: StatPill(
                  data: StatData.counter(
                    Icons.quiz_rounded,
                    quizzesCompleted,
                    'Quizzes',
                    AppColors.duoBlue,
                  ),
                  isDark: isDark,
                  delay: 160,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBentoChild(
                index: 3,
                child: StatPill(
                  data: StatData.counter(
                    Icons.timer_rounded,
                    learningTime,
                    'Time',
                    AppColors.primary,
                    suffix: 'm',
                  ),
                  isDark: isDark,
                  delay: 240,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════ STAT PILL ═══════════════

class StatPill extends StatelessWidget {
  final StatData data;
  final bool isDark;
  final int delay;

  const StatPill({
    super.key,
    required this.data,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(data.icon, color: data.color, size: 20),
          const SizedBox(height: 6),
          if (data.numericValue != null)
            AnimatedCounter(
              value: data.numericValue!,
              suffix: data.suffix,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            )
          else
            Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            data.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 200 + delay),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}

// ═══════════════ SKILL PROGRESS CARD ═══════════════

class SkillProgressCard extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final bool isDark;
  final int delay;

  const SkillProgressCard({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: Duration(milliseconds: 1000 + delay),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 300 + delay),
      duration: 400.ms,
    );
  }
}

// ═══════════════ SKILLS GRID ═══════════════

class SkillsGrid extends StatelessWidget {
  final bool isDark;
  final bool isTablet;
  final UserStatsEntity stats;

  const SkillsGrid({
    super.key,
    required this.isDark,
    required this.isTablet,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final skills = [
      SkillData('Alphabet', stats.alphabetProgress, AppColors.duoBlue),
      SkillData('Numbers', stats.numbersProgress, AppColors.duoOrange),
      SkillData('Vocabulary', stats.vocabularyProgress, AppColors.duoGreen),
      SkillData('Rhymes', stats.rhymesProgress, AppColors.primary),
    ];

    return Row(
      children: skills.asMap().entries.map((entry) {
        final i = entry.key;
        final skill = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < skills.length - 1 ? 10 : 0),
            child: SkillProgressCard(
              label: skill.label,
              progress: skill.progress,
              color: skill.color,
              isDark: isDark,
              delay: i * 100,
            ),
          ),
        );
      }).toList(),
    );
  }
}
