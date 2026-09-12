import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/providers/providers.dart';
import 'sidebar_avatar_icon.dart';
import 'theme_toggle_switch.dart';

class DesktopSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isDark;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(userStatsProvider).value?.currentStreak ?? 0;

    return Container(
      width: ResponsiveLayout.leftSidebarWidth,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),

          // ── Brand ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.emeraldDeep],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: isDark ? 0 : 0.6),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'ᱚ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: AppColors.shadowSoftBlack,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olitun',
                        style: AppTypography.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : AppColors.webInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SANTALI • OL CHIKI',
                        style: AppTypography.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : AppColors.emeraldDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ── Section label ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'MENU',
              style: AppTypography.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: isDark ? Colors.white38 : AppColors.webSlateLight,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Nav items ────────────────────────────────────────
          SidebarNavItem(
            icon: Icons.school_rounded,
            label: l10n.navLearn,
            caption: 'Lessons • Words • Quiz',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            isDark: isDark,
          ),
          SidebarNavItem(
            icon: Icons.music_note_rounded,
            label: l10n.navBakhed,
            caption: 'Rhymes • Listening',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
            isDark: isDark,
          ),
          SidebarNavItem(
            icon: Icons.person_rounded,
            leading: const SidebarAvatarIcon(),
            label: l10n.navProfile,
            caption: 'Stars • Streak • Goals',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            isDark: isDark,
          ),

          const Spacer(),

          // ── Streak nudge ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.nightElevated, AppColors.nightPanel],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.webInk, AppColors.santaliSalGreen],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.amberEmber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.amberEmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.amberEmber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak day streak',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streak > 0 ? 'Keep it burning' : 'Start today',
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Animated theme switch ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AnimatedThemeToggle(
                isDark: isCurrentlyDark,
                targetLabel: isCurrentlyDark ? l10n.light : l10n.dark,
                onToggle: (toDark) =>
                    updateThemeMode(ref, toDark ? 'dark' : 'light'),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Center(
            child: Text(
              'Olitun PWA • v2.4',
              style: AppTypography.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: isDark ? Colors.white24 : AppColors.webSlateLight,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class SidebarNavItem extends StatefulWidget {
  final IconData icon;

  /// Custom leading widget (e.g. the animated profile avatar) replacing
  /// the default icon box.
  final Widget? leading;
  final String label;
  final String caption;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const SidebarNavItem({
    super.key,
    required this.icon,
    this.leading,
    required this.label,
    this.caption = '',
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final hovered = _isHovered && !isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          selected: widget.isSelected,
          label: AppLocalizations.of(context)!.navItemSemantics(widget.label),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(
                          alpha: widget.isDark ? 0.14 : 0.10,
                        )
                      : hovered
                      ? (widget.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.045)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: isActive
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                        )
                      : Border.all(color: Colors.transparent),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -6,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.emeraldDeep,
                                ],
                              )
                            : null,
                        color: isActive
                            ? null
                            : (widget.isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child:
                          widget.leading ??
                          Icon(
                            widget.icon,
                            size: 21,
                            color: isActive
                                ? Colors.white
                                : widget.isDark
                                ? Colors.white60
                                : AppColors.webSlate,
                          ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: AppTypography.inter(
                              fontSize: 15,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              letterSpacing: -0.1,
                              color: isActive
                                  ? (widget.isDark
                                        ? Colors.white
                                        : AppColors.emeraldPine)
                                  : widget.isDark
                                  ? Colors.white70
                                  : AppColors.webSlateDark,
                            ),
                          ),
                          if (widget.caption.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.caption,
                              style: AppTypography.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.9)
                                    : widget.isDark
                                    ? Colors.white38
                                    : AppColors.webSlateLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
