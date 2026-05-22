import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../../../../core/motion/confetti_overlay.dart';
import '../providers/mission_providers.dart';

class TodayMissionCard extends ConsumerStatefulWidget {
  const TodayMissionCard({super.key});

  @override
  ConsumerState<TodayMissionCard> createState() => _TodayMissionCardState();
}

class _TodayMissionCardState extends ConsumerState<TodayMissionCard> {
  bool _isHidden = false;
  bool _showConfetti = false;
  bool _wasCompletedOnInit = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    final lessonCompleted = ref.read(lessonCompletedTodayProvider);
    final quizTaken = ref.read(quizTakenTodayProvider);
    final bakhedListened = ref.read(bakhedListenedTodayProvider);
    final quickWinCompleted = ref.read(quickWinCompletedTodayProvider);
    final completedCount =
        (lessonCompleted ? 1 : 0) +
        (quizTaken ? 1 : 0) +
        (bakhedListened ? 1 : 0) +
        (quickWinCompleted ? 1 : 0);

    if (completedCount == 4) {
      _wasCompletedOnInit = true;
      _isHidden = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden && !_showConfetti && !_isAnimating) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lessonCompleted = ref.watch(lessonCompletedTodayProvider);
    final quizTaken = ref.watch(quizTakenTodayProvider);
    final bakhedListened = ref.watch(bakhedListenedTodayProvider);
    final quickWinCompleted = ref.watch(quickWinCompletedTodayProvider);

    final completedCount =
        (lessonCompleted ? 1 : 0) +
        (quizTaken ? 1 : 0) +
        (bakhedListened ? 1 : 0) +
        (quickWinCompleted ? 1 : 0);

    final progress = completedCount / 4;

    if (progress == 1.0 &&
        !_isHidden &&
        !_wasCompletedOnInit &&
        !_showConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showConfetti = true;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() {
            _showConfetti = false;
            _isAnimating = true;
            _isHidden = true;
          });
        });
      });
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      onEnd: () {
        if (mounted && _isHidden) {
          setState(() {
            _isAnimating = false;
          });
        }
      },
      child: _isHidden
          ? const SizedBox.shrink()
          : Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Today's Mission",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: progress == 1.0
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white10 : Colors.black12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedCount/4 Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: progress == 1.0
                                    ? (isDark
                                          ? AppColors.brandTextDark
                                          : AppColors.brandTextLight)
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Custom Thin Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? AppColors.brandTextDark
                                : AppColors.brandTextLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildMissionItem(
                        context: context,
                        title: 'Complete 1 lesson',
                        completed: lessonCompleted,
                        isDark: isDark,
                        onTap: () {
                          ref
                              .read(lessonCompletedTodayProvider.notifier)
                              .toggle();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMissionItem(
                        context: context,
                        title: 'Take 1 quick quiz',
                        completed: quizTaken,
                        isDark: isDark,
                        onTap: () {
                          ref.read(quizTakenTodayProvider.notifier).toggle();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMissionItem(
                        context: context,
                        title: 'Listen to 1 Bakhed',
                        completed: bakhedListened,
                        isDark: isDark,
                        onTap: () {
                          ref
                              .read(bakhedListenedTodayProvider.notifier)
                              .toggle();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMissionItem(
                        context: context,
                        title: 'Quick Win: Review 1 word (takes 20s)',
                        completed: quickWinCompleted,
                        isDark: isDark,
                        onTap: () {
                          ref
                              .read(quickWinCompletedTodayProvider.notifier)
                              .toggle();
                        },
                      ),
                      if (progress == 1.0) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      const Color(0xFF1E293B),
                                    ]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.08),
                                      Colors.white,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '✨',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tomorrow Preview',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Learn: Family Words',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.brandTextDark
                                      : AppColors.brandTextLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reward: 30 stars\nCome back tomorrow to continue your streak!',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showConfetti)
                  const Positioned.fill(
                    child: ConfettiBurst(particleCount: 60),
                  ),
              ],
            ),
    );
  }

  Widget _buildMissionItem({
    required BuildContext context,
    required String title,
    required bool completed,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return MinimumTapTarget(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.01)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: completed
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : Colors.black38),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: completed
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: completed ? FontWeight.bold : FontWeight.normal,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  color: completed
                      ? (isDark ? Colors.white60 : Colors.black54)
                      : (isDark ? Colors.white : const Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
