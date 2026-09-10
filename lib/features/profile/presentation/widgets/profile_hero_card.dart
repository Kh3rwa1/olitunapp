import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/features/profile/presentation/providers/weekly_leaderboard_provider.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileHeroCard extends ConsumerWidget {
  final String userName;
  final List<Color> avatarColors;

  /// Catalog avatar id or [kInitialAvatarId]. Unknown values show the default
  /// animation while the explicit name-initial choice remains persistent.
  final String avatarId;
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
    required this.avatarId,
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
      AppColors.xpNeutral,
      AppColors.brandBlue,
      AppColors.accentOchre,
      AppColors.accentGold,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardLabel = ref
        .watch(weeklyLeaderboardProvider)
        .when(
          data: (leaderboard) => leaderboard.badgeLabel,
          error: (_, _) => 'Leaderboard unavailable',
          loading: () => 'Leaderboard · Loading…',
        );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final compact = MediaQuery.sizeOf(context).width < 380;
    final avatarSize = compact ? 72.0 : 84.0;
    final safeProgress = overallProgress.clamp(0.0, 1.0).toDouble();
    final avatarLabel = usesProfileInitial(avatarId)
        ? 'Name initial'
        : profileAvatarById(avatarId)?.label ?? kProfileAvatars.first.label;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
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
              Semantics(
                button: true,
                label: 'Change profile avatar',
                value: avatarLabel,
                child: PressableScale(
                  onTap: onEditAvatar,
                  haptic: HapticIntensity.selection,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
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
                          child: !usesProfileInitial(avatarId)
                              ? ClipOval(
                                  child: Lottie.asset(
                                    avatarAssetPath(avatarId),
                                    width: avatarSize,
                                    height: avatarSize,
                                    fit: BoxFit.cover,
                                    animate: !reduceMotion,
                                    repeat: !reduceMotion,
                                    errorBuilder: (_, _, _) => _AvatarInitial(
                                      userName: userName,
                                      compact: compact,
                                    ),
                                  ),
                                )
                              : _AvatarInitial(
                                  userName: userName,
                                  compact: compact,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 26,
                          height: 26,
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
                            size: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 20),
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
                              fontSize: compact ? 22 : 26,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          button: true,
                          label: 'Edit display name',
                          child: PressableScale(
                            onTap: onEditName,
                            haptic: HapticIntensity.selection,
                            child: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
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
                        Semantics(
                          liveRegion: true,
                          label:
                              '$leaderboardLabel. Current learner level: $level',
                          child: ExcludeSemantics(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getLevelColor().withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getLevelColor().withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    size: 14,
                                    color: _getLevelColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    leaderboardLabel,
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _getLevelColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (memberSince != null)
                          Text(
                            'Since ${_formatDate(memberSince!)}',
                            style: AppTypography.inter(
                              fontSize: 12,
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
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Overall Progress',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  Text(
                    '${(safeProgress * 100).toInt()}%',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: safeProgress),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
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

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.userName, required this.compact});

  final String userName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      userName.isNotEmpty ? userName[0].toUpperCase() : 'L',
      style: AppTypography.inter(
        fontSize: compact ? 30 : 34,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
