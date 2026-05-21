import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../providers/mission_providers.dart';

class TodayMissionCard extends ConsumerWidget {
  const TodayMissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lessonCompleted = ref.watch(lessonCompletedTodayProvider);
    final quizTaken = ref.watch(quizTakenTodayProvider);
    final bakhedListened = ref.watch(bakhedListenedTodayProvider);

    final completedCount =
        (lessonCompleted ? 1 : 0) +
        (quizTaken ? 1 : 0) +
        (bakhedListened ? 1 : 0);

    final progress = completedCount / 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                      color: AppColors.primary.withValues(alpha: 0.15),
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  '$completedCount/3 Done',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0
                        ? (isDark
                              ? AppColors.brandTextDark
                              : AppColors.brandTextLight)
                        : (isDark ? Colors.white70 : Colors.black87),
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
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.brandTextDark : AppColors.brandTextLight,
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
              ref.read(lessonCompletedTodayProvider.notifier).toggle();
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
              ref.read(bakhedListenedTodayProvider.notifier).toggle();
            },
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
