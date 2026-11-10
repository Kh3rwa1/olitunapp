// Home header: day-part pill, "Johar, {name}", subtitle, and the Today strip
// (streak · goal ring · due reviews) — the first thing a returning learner
// sees, so the habit state is visible in the first frame.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'today_strip.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.isDark,
    required this.isNewcomer,
    this.now,
  });

  final String userName;
  final bool isDark;
  final bool isNewcomer;

  /// Clock for the day-part greeting (tests pin it).
  final DateTime? now;

  static String monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month.clamp(1, 12)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final current = now ?? DateTime.now();
    final hour = current.hour;
    final dayPart = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final firstName = userName.trim().isEmpty ? 'Olitun' : userName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.greetingDayPart(dayPart).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const Spacer(),
              Text(
                '${current.day} ${monthName(current.month)} • ${l10n.homeExploreHint}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.webSlateLight,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.joharUser(firstName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isDesktop ? 40 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            height: 1.05,
            color: isDark ? Colors.white : AppColors.webInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isNewcomer ? l10n.homeNewcomerSubtitle : l10n.homePickupSubtitle,
          style: TextStyle(
            fontSize: isDesktop ? 15 : 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : AppColors.webSlate,
          ),
        ),
        const SizedBox(height: 14),
        const TodayStrip(),
      ],
    );
  }
}
