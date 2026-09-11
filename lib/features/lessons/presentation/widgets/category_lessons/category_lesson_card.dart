import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/utils/localized_content.dart';
import '../../../domain/entities/lesson_entity.dart';

class CategoryLessonCard extends StatefulWidget {
  final LessonEntity lesson;
  final String primaryTitle;
  final String secondaryTitle;
  final String scriptMode;
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Color themeColor;
  final bool isLocked;
  final bool isCompleted;

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
    this.isLocked = false,
    this.isCompleted = false,
  });

  @override
  State<CategoryLessonCard> createState() => _CategoryLessonCardState();
}

class _CategoryLessonCardState extends State<CategoryLessonCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isLocked = widget.isLocked;
    final isCompleted = widget.isCompleted;
    final themeColor = widget.themeColor;
    final activeBgColor = isDark
        ? const Color(0xFF101724).withValues(alpha: 0.85)
        : Colors.white;
    final lockedBgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF8FAFC);
    final activeBorderColor = _hover && !isLocked
        ? themeColor.withValues(alpha: 0.35)
        : isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE3E8F0);
    final lockedBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE3E8F0);
    final semanticState = isLocked
        ? 'Locked. Complete the previous lesson first.'
        : isCompleted
        ? 'Completed. Available to replay.'
        : 'Unlocked.';

    return Semantics(
      button: true,
      label: '${widget.primaryTitle}. $semanticState',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: PressableScale(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: _hover && !isLocked
                ? Matrix4.translationValues(0, -2, 0)
                : Matrix4.identity(),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isLocked ? lockedBgColor : activeBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLocked ? lockedBorderColor : activeBorderColor,
                width: 1.2,
              ),
              boxShadow: isDark || isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: _hover ? 0.08 : 0.05),
                        blurRadius: _hover ? 28 : 20,
                        offset: Offset(0, _hover ? 14 : 8),
                        spreadRadius: -12,
                      ),
                      BoxShadow(
                        color: themeColor.withValues(
                          alpha: _hover ? 0.10 : 0.05,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                        spreadRadius: -18,
                      ),
                    ],
            ),
            child: Opacity(
              opacity: isLocked ? 0.72 : 1,
              child: Hero(
                tag: MotionTokens.heroTag('lesson', widget.lesson.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLevelBadge(widget.lesson.level, isDark),
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: Color(0xFF00A355),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'DONE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF00A355),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.primaryTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.25,
                              height: 1.25,
                              fontFamily: primaryLocalizedFontFamily(
                                widget.scriptMode,
                              ),
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (widget.secondaryTitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.secondaryTitle,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OlChiki',
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                          if (widget.lesson.description != null &&
                              widget.lesson.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.lesson.description!,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLocked
                                    ? Icons.lock_outline_rounded
                                    : isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.cloud_done_rounded,
                                size: 14,
                                color: isLocked
                                    ? (isDark
                                          ? Colors.white54
                                          : const Color(0xFF94A3B8))
                                    : const Color(0xFF00A355),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLocked
                                    ? 'Complete previous lesson'
                                    : isCompleted
                                    ? 'Completed · Replay anytime'
                                    : 'Available offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildCTA(isDark),
                  ],
                ),
              ),
            ),
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
        badgeColor = const Color(0xFF00A355);
        label = 'Beginner';
        icon = Icons.star_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.32 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(bool isDark) {
    final isLocked = widget.isLocked;
    final isCompleted = widget.isCompleted;
    final icon = isLocked
        ? Icons.lock_rounded
        : isCompleted
        ? Icons.replay_rounded
        : Icons.play_arrow_rounded;
    final hovered = _hover && !isLocked;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: hovered ? 52 : 48,
      height: hovered ? 52 : 48,
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06))
            : null,
        gradient: isLocked ? null : widget.gradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLocked
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: widget.themeColor.withValues(
                    alpha: hovered ? 0.5 : 0.35,
                  ),
                  blurRadius: hovered ? 18 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: isLocked
              ? (isDark ? Colors.white54 : const Color(0xFF94A3B8))
              : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
