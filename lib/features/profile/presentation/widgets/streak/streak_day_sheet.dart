import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/models/content/quiz_model.dart';
import '../../../domain/entities/user_stats_entity.dart';
import '../../../domain/streak_week_logic.dart';

class StreakDaySheet extends StatelessWidget {
  final DateTime day;
  final UserStatsEntity stats;
  final Map<String, QuizModel> quizTitles;
  final bool isDark;

  const StreakDaySheet({
    super.key,
    required this.day,
    required this.stats,
    required this.quizTitles,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime day,
    required UserStatsEntity stats,
    required Map<String, QuizModel> quizTitles,
    required bool isDark,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: StreakDaySheet(
          day: day,
          stats: stats,
          quizTitles: quizTitles,
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final key = StreakWeekLogic.dateKey(day);

    final activities = <String>[
      for (final result in stats.quizHistory.values)
        if (StreakWeekLogic.dateKey(
              DateTime.parse(result.completedAt).toLocal(),
            ) ==
            key)
          '${l10n.dayDetailQuiz} · '
              '${quizTitles[result.quizId]?.title ?? _prettyQuizId(result.quizId)}',
      if (stats.practiceDates.contains(key)) l10n.dayDetailPracticeSession,
      if (stats.lastActiveDate == key && stats.currentStreak > 0)
        l10n.dayDetailStreakDay,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fullDayName(day.weekday)}, ${_monthName(day.month)} ${day.day}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.nights_stay_outlined,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.dayDetailNoActivity,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            )
          else
            for (final activity in activities)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.accentOchre,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _prettyQuizId(String id) {
    final cleaned = id.replaceAll(RegExp(r'^quiz_'), '').replaceAll('_', ' ');
    if (cleaned.isEmpty) return 'Quiz';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static String _fullDayName(int weekday) {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];
  }

  static String _monthName(int m) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][m - 1];
  }
}
