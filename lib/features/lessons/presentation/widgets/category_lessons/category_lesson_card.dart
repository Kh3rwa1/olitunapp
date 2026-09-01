import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/utils/localized_content.dart';

class CategoryLessonCard extends StatelessWidget {
  final dynamic lesson;
  final String primaryTitle;
  final String secondaryTitle;
  final String scriptMode;
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Color themeColor;

  const CategoryLessonCard({
    super.key,
    required this.lesson,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.scriptMode,
    required this.isDark,
    required this.index,
    required this.onTap,
    required this.gradient,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
        : Colors.white;

    final activeBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    return PressableScale(
      onTap: onTap,
      child: Hero(
        tag: MotionTokens.heroTag('lesson', lesson.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: activeBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeBorderColor),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [_buildLevelBadge(lesson.level, isDark)]),
                    const SizedBox(height: 10),
                    Text(
                      primaryTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: primaryLocalizedFontFamily(scriptMode),
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (secondaryTitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        secondaryTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'OlChiki',
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                    if (lesson.description != null &&
                        lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black54,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 13,
                          color: themeColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Available Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildCTA(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level, bool isDark) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (level.toLowerCase()) {
      case 'advanced':
        badgeColor = AppColors.accentTerracotta;
        label = 'Advanced';
        icon = Icons.whatshot_rounded;
        break;
      case 'intermediate':
        badgeColor = AppColors.accentOchre;
        label = 'Intermediate';
        icon = Icons.bolt_rounded;
        break;
      case 'beginner':
      default:
        badgeColor = AppColors.accentForest;
        label = 'Beginner';
        icon = Icons.star_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
