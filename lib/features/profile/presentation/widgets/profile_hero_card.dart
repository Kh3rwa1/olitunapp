import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileHeroCard extends StatelessWidget {
  final String userName;
  final List<Color> avatarColors;
  final String avatarEmoji;
  final String level;
  final int levelIndex;

  /// ISO yyyy-MM-dd, or null when unknown (line is hidden rather than guessed).
  final String? memberSince;
  final double overallProgress;
  final bool isDark;
  final VoidCallback onEditName;
  final VoidCallback onEditAvatar;

  const ProfileHeroCard({
    super.key,
    required this.userName,
    required this.avatarColors,
    required this.avatarEmoji,
    required this.level,
    required this.levelIndex,
    this.memberSince,
    required this.overallProgress,
    required this.isDark,
    required this.onEditName,
    required this.onEditAvatar,
  });

  Color _getLevelColor() {
    const colors = [
      AppColors.xpNeutral, // Beginner — grey
      AppColors.duoBlue, // Intermediate — blue
      AppColors.duoOrange, // Advanced — orange
      AppColors.duoYellow, // Master — gold
    ];
    return colors[levelIndex.clamp(0, 3)];
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      const months = [
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
      return '${months[int.parse(parts[1])]} ${parts[2]}, ${parts[0]}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [Colors.white, Colors.white.withValues(alpha: 0.9)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              PressableScale(
                onTap: onEditAvatar,
                haptic: HapticIntensity.selection,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: avatarColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: avatarColors[0].withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: avatarEmoji.isNotEmpty
                            ? Text(
                                avatarEmoji,
                                style: const TextStyle(fontSize: 32),
                              )
                            : Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'L',
                                style: AppTypography.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Name + Level + Member Since
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: AppTypography.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PressableScale(
                          onTap: onEditName,
                          haptic: HapticIntensity.selection,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getLevelColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                levelIndex >= 3
                                    ? Icons.workspace_premium_rounded
                                    : levelIndex >= 2
                                    ? Icons.diamond_rounded
                                    : Icons.school_rounded,
                                size: 12,
                                color: _getLevelColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                level,
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getLevelColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Hidden entirely when creation date is unknown —
                        // never guess a member-since date.
                        if (memberSince != null)
                          Text(
                            'Since ${_formatDate(memberSince!)}',
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: overallProgress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
