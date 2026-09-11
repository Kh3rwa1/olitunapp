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
    final levelColor = _getLevelColor();

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
                child: LayoutBuilder(
                  builder: (context, detailsConstraints) {
                    return Column(
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
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black26,
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
                            _ExpandableLeaderboardBadge(
                              label: leaderboardLabel,
                              level: level,
                              color: levelColor,
                              maxWidth: detailsConstraints.maxWidth,
                              reduceMotion: reduceMotion,
                            ),
                            if (memberSince != null)
                              Text(
                                'Since ${_formatDate(memberSince!)}',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black38,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
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

class _ExpandableLeaderboardBadge extends StatefulWidget {
  const _ExpandableLeaderboardBadge({
    required this.label,
    required this.level,
    required this.color,
    required this.maxWidth,
    required this.reduceMotion,
  });

  final String label;
  final String level;
  final Color color;
  final double maxWidth;
  final bool reduceMotion;

  @override
  State<_ExpandableLeaderboardBadge> createState() =>
      _ExpandableLeaderboardBadgeState();
}

class _ExpandableLeaderboardBadgeState
    extends State<_ExpandableLeaderboardBadge> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);
    final availableWidth = widget.maxWidth.isFinite ? widget.maxWidth : 280.0;
    final collapsedWidth = availableWidth > 260.0 ? 260.0 : availableWidth;

    return Semantics(
      liveRegion: true,
      child: PressableScale(
        key: const ValueKey('profile-leaderboard-action'),
        onTap: _toggleExpanded,
        scale: 0.97,
        haptic: HapticIntensity.selection,
        semanticLabel:
            '${widget.label}. Current learner level: ${widget.level}. '
            '${_expanded ? 'Expanded. Tap to collapse.' : 'Tap to enlarge.'}',
        child: AnimatedSize(
          duration: duration,
          reverseDuration: duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            key: const ValueKey('profile-leaderboard-chip'),
            duration: duration,
            curve: Curves.easeOutCubic,
            width: _expanded ? availableWidth : collapsedWidth,
            padding: EdgeInsets.symmetric(
              horizontal: _expanded ? 14 : 12,
              vertical: _expanded ? 10 : 6,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(_expanded ? 18 : 20),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: _expanded ? 1.22 : 1,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    style: AppTypography.inter(
                      fontSize: _expanded ? 14 : 12,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: _expanded ? null : 1,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      softWrap: _expanded,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
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
