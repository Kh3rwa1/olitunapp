import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../providers/profile_providers.dart';

class MasteryMilestonesCard extends ConsumerWidget {
  final UserStatsEntity stats;

  const MasteryMilestonesCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Traditional Badge Names from Admin CMS settings (via providers)
    final archerName = ref.watch(badgeTraditionalArcherNameProvider);
    final kudumName = ref.watch(badgeTraditionalKudumNameProvider);
    final kherwalName = ref.watch(badgeTraditionalKherwalNameProvider);

    // Achievements definitions
    final milestones = [
      _MilestoneData(
        title: archerName,
        subtitle: 'Practice 20+ letters',
        icon: Icons.track_changes_rounded,
        color: AppColors.primary,
        isUnlocked: stats.practicedLetters.length >= 20,
        currentProgress: stats.practicedLetters.length.toDouble(),
        targetProgress: 20.0,
        progressLabel: '${stats.practicedLetters.length}/20 letters',
        isTraditional: true,
      ),
      _MilestoneData(
        title: kudumName,
        subtitle: 'Complete 3+ lessons',
        icon: Icons.psychology_rounded,
        color: AppColors.duoOrange,
        isUnlocked: stats.completedLessons.length >= 3,
        currentProgress: stats.completedLessons.length.toDouble(),
        targetProgress: 3.0,
        progressLabel: '${stats.completedLessons.length}/3 lessons',
        isTraditional: true,
      ),
      _MilestoneData(
        title: kherwalName,
        subtitle: 'Reach 40%+ progress',
        icon: Icons.spa_rounded,
        color: AppColors.duoYellow,
        isUnlocked: stats.overallProgress >= 0.4,
        currentProgress: stats.overallProgress,
        targetProgress: 0.4,
        progressLabel: '${(stats.overallProgress * 100).round()}%/40%',
        isTraditional: true,
      ),
      _MilestoneData(
        title: 'Daily Voyager',
        subtitle: 'Active 3+ day streak',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.duoBlue,
        isUnlocked: stats.currentStreak >= 3,
        currentProgress: stats.currentStreak.toDouble(),
        targetProgress: 3.0,
        progressLabel: '${stats.currentStreak}/3 days',
        isTraditional: false,
      ),
      _MilestoneData(
        title: 'Communicator',
        subtitle: 'Learn for 10+ minutes',
        icon: Icons.record_voice_over_rounded,
        color: const Color(0xFF00E5FF),
        isUnlocked: stats.totalLearningMinutes >= 10,
        currentProgress: stats.totalLearningMinutes.toDouble(),
        targetProgress: 10.0,
        progressLabel: '${stats.totalLearningMinutes}/10 mins',
        isTraditional: false,
      ),
      _MilestoneData(
        title: 'Star Gazer',
        subtitle: 'Earn 50+ stars',
        icon: Icons.star_rounded,
        color: AppColors.duoYellow,
        isUnlocked: stats.totalStars >= 50,
        currentProgress: stats.totalStars.toDouble(),
        targetProgress: 50.0,
        progressLabel: '${stats.totalStars}/50 stars',
        isTraditional: false,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorder.withValues(alpha: 0.5) 
              : AppColors.lightBorder.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Milestone Achievements',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock traditional and modern mastery badges',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
              // Traditional Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'CULTURE & FOLK',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3x2 Bento grid of milestones
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: milestones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final data = milestones[index];
              return AnimatedBentoChild(
                index: index,
                child: _MilestoneMedallion(data: data),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

class _MilestoneData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double currentProgress;
  final double targetProgress;
  final String progressLabel;
  final bool isTraditional;

  _MilestoneData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.currentProgress,
    required this.targetProgress,
    required this.progressLabel,
    required this.isTraditional,
  });
}

class _MilestoneMedallion extends StatefulWidget {
  final _MilestoneData data;

  const _MilestoneMedallion({required this.data});

  @override
  State<_MilestoneMedallion> createState() => _MilestoneMedallionState();
}

class _MilestoneMedallionState extends State<_MilestoneMedallion> {
  bool _showConfetti = false;
  Timer? _confettiTimer;
  int _shakeKey = 0;

  void _triggerLocalExplosion() {
    if (!widget.data.isUnlocked) {
      // Locked feedback - minor warning haptic & shake animation
      HapticFeedback.mediumImpact();
      setState(() {
        _shakeKey++;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keep going! ${widget.data.subtitle} to unlock this badge. 🔒',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.duoOrange,
        ),
      );
      return;
    }

    // Unlocked and tapped -> trigger radial explosion
    HapticFeedback.lightImpact();
    
    _confettiTimer?.cancel();
    setState(() {
      _showConfetti = true;
    });

    _confettiTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;
    
    // Calculate progress ratio (capped at 1.0)
    final progressRatio = (data.currentProgress / data.targetProgress).clamp(0.0, 1.0);

    Widget medallionCard = Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.isUnlocked
              ? data.color.withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          width: 1.5,
        ),
        boxShadow: data.isUnlocked
            ? [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing circular bubble containing the badge icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: data.isUnlocked
                      ? LinearGradient(
                          colors: [data.color, data.color.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0),
                            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F5),
                          ],
                        ),
                  boxShadow: data.isUnlocked
                      ? [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  data.isUnlocked ? data.icon : Icons.lock_outline_rounded,
                  color: data.isUnlocked 
                      ? Colors.white 
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 26,
                ),
              ),
              if (data.isTraditional && data.isUnlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.duoOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Title (editable or static)
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: data.isUnlocked
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white30 : Colors.black38),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Subtitle / Criteria
          Text(
            data.subtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 5,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [data.color, data.color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.progressLabel,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: data.isUnlocked
                      ? data.color
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );

    if (_shakeKey > 0) {
      medallionCard = medallionCard
          .animate(key: ValueKey(_shakeKey))
          .shake(duration: 350.ms, hz: 6, curve: Curves.easeOutQuad, offset: const Offset(4.0, 0.0));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _triggerLocalExplosion,
          child: medallionCard,
        ),
        
        // Local Confetti burst rendered right on top of this medallion
        if (_showConfetti)
          const Positioned.fill(
            child: ConfettiBurst(
              particleCount: 28,
              colors: [
                Color(0xFF1EE088), // Logo primary green
                Color(0xFFFF9600), // Duo Orange
                Color(0xFFFFC800), // Duo Yellow
                Color(0xFF1CB0F6), // Duo Blue
                Color(0xFF00C767), // Darker green
              ],
            ),
          ),
      ],
    );
  }
}
