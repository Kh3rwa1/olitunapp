import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/gamification_content_provider.dart';
import '../../domain/entities/user_stats_entity.dart';
import 'badges/badge_detail_dialog.dart';
import 'badges/badge_item_model.dart';

export 'badges/badge_item_model.dart';

class BadgesGridWidget extends ConsumerStatefulWidget {
  final UserStatsEntity stats;
  final bool isDark;

  const BadgesGridWidget({
    super.key,
    required this.stats,
    required this.isDark,
  });

  @override
  ConsumerState<BadgesGridWidget> createState() => _BadgesGridWidgetState();
}

class _BadgesGridWidgetState extends ConsumerState<BadgesGridWidget> {
  String _selectedCategory = 'ALL';

  List<Badge> _getBadges() {
    final remoteBadges = ref
        .watch(userGamificationSummaryProvider)
        .valueOrNull
        ?.badges;
    return BadgeCatalog.resolveBadges(
      stats: widget.stats,
      remoteBadges: remoteBadges,
    );
  }

  void _showBadgeDialog(BuildContext context, Badge badge) {
    BadgeDetailDialog.show(context, badge: badge, isDark: widget.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final allBadges = _getBadges();
    const categories = [
      'ALL',
      'LEARNING',
      'CULTURE',
      'HABIT',
      'CIRCLE',
      'QUIZ',
    ];

    final filteredBadges = _selectedCategory == 'ALL'
        ? allBadges
        : allBadges.where((b) => b.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pill Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Grid of Badges
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                return GestureDetector(
                  onTap: () => _showBadgeDialog(context, badge),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      borderRadius: AppRadius.borderXxl,
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: widget.isDark
                          ? []
                          : const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                (badge.isUnlocked
                                        ? AppColors.primary
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              badge.icon,
                              style: TextStyle(
                                fontSize: 22,
                                color: badge.isUnlocked ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            badge.name,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badge.isUnlocked
                                  ? (widget.isDark
                                        ? Colors.white
                                        : Colors.black)
                                  : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Unlocked or Locked Progress Indicator
                        if (badge.isUnlocked)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                badge.rewardStars > 0 ? 'REWARDED' : 'UNLOCKED',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'LOCKED (${badge.currentProgress}/${badge.targetProgress})',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: widget.isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().scale(
                  delay: Duration(milliseconds: index * 40),
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
