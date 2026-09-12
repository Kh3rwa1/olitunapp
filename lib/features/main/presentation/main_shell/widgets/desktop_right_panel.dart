import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/providers/providers.dart';

class DesktopRightPanel extends ConsumerWidget {
  final bool isDark;

  const DesktopRightPanel({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final streak = statsAsync.value?.currentStreak ?? 0;
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final learningTime = statsAsync.value?.totalLearningMinutes ?? 0;
    final userName = ref.watch(userNameProvider);
    final displayName = userName.isEmpty ? 'Olitun' : userName;

    return Container(
      width: ResponsiveLayout.rightSidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.quizDarkBackground : Colors.white,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AppColors.webCanvasWarm],
              ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.emeraldTeal,
                    AppColors.emeraldShade,
                    AppColors.emeraldInk,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldShade.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -40,
                    child: Text(
                      'ᱚ',
                      style: TextStyle(
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'O',
                                style: AppTypography.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emeraldInk,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'SANTALI LEARNER',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 15,
                              color: AppColors.goldSoft,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                streak > 0
                                    ? '$streak day streak — superb'
                                    : 'Start your first streak today',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'YOUR STATS',
              style: AppTypography.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: isDark ? Colors.white38 : AppColors.webSlateLight,
              ),
            ),
            const SizedBox(height: 12),

            // 2×2 stat grid — compact, scannable, premium.
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Day streak',
                    tint: AppColors.amberEmber,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.star_rounded,
                    value: '$stars',
                    label: 'Stars',
                    tint: AppColors.accentGold,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.emoji_events_rounded,
                    value: '$lessonsCompleted',
                    label: 'Lessons',
                    tint: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.timer_rounded,
                    value: '${learningTime}m',
                    label: 'Focus time',
                    tint: AppColors.brandBlue,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Daily goal ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.webBorder,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                          spreadRadius: -12,
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          size: 16,
                          color: AppColors.emeraldDeep,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Daily goal',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: isDark ? Colors.white : AppColors.webInk,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${lessonsCompleted % 3}/3',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDeep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (lessonsCompleted % 3) / 3 == 0
                          ? 0.06
                          : (lessonsCompleted % 3) / 3,
                      minHeight: 9,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.webInk.withValues(alpha: 0.07),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Finish 3 lessons to keep your streak alive.',
                    style: AppTypography.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? Colors.white54 : AppColors.webSlate,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.elevatedButtonFg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      child: const Text('Continue learning →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    required this.isDark,
  });

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hover
            ? Matrix4.diagonal3Values(1.03, 1.03, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: _hover ? 0.06 : 0.035)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hover
                ? widget.tint.withValues(alpha: 0.3)
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.webBorder),
          ),
          boxShadow: widget.isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.webInk.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -10,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, color: widget.tint, size: 17),
            ),
            const SizedBox(height: 10),
            Text(
              widget.value,
              style: AppTypography.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: widget.isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            Text(
              widget.label,
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppColors.webSlateLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
