// Shown once per lost streak: the stored counter still says N but no practice
// landed today or yesterday. Honest, supportive, and gone after one dismiss
// (acknowledgeStreakLost) so Home never nags about the same loss twice.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../practice/daily/presentation/daily_practice_screen.dart';
import '../../../profile/presentation/providers/user_stats_provider.dart';
import '../providers/displayed_streak_provider.dart';

class StreakLostCard extends ConsumerStatefulWidget {
  const StreakLostCard({super.key});

  @override
  ConsumerState<StreakLostCard> createState() => _StreakLostCardState();
}

class _StreakLostCardState extends ConsumerState<StreakLostCard> {
  bool _logged = false;

  void _logSeen(int lostStreak) {
    if (_logged) return;
    _logged = true;
    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.streakLostSeen,
            source: 'home',
            metadata: {'lostStreak': lostStreak},
          ),
    );
  }

  Future<void> _dismiss() async {
    final stats = ref.read(userStatsProvider).valueOrNull;
    if (stats == null) return;
    await acknowledgeStreakLost(ref.read(sharedPreferencesProvider), stats);
    ref.invalidate(streakLostProvider);
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(streakLostProvider);
    final stats = ref.watch(userStatsProvider).valueOrNull;
    if (!show || stats == null) return const SizedBox.shrink();
    final lost = stats.currentStreak;
    _logSeen(lost);

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.quizDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.amberEmber.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.amberEmber,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.streakLostTitle(lost),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.webInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.streakLostBody,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: isDark ? Colors.white60 : AppColors.webSlate,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.streakLostDismiss,
                onPressed: _dismiss,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : AppColors.webSlateLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              onPressed: () async {
                await _dismiss();
                if (context.mounted) context.push(dailyPracticeRoute);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.amberEmber.withValues(
                  alpha: isDark ? 0.22 : 0.14,
                ),
                foregroundColor: isDark ? Colors.white : AppColors.webInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.streakLostCta,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
