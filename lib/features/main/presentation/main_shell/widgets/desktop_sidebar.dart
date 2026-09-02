import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/presentation/layout/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/providers/providers.dart';

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

    return Container(
      width: ResponsiveLayout.leftSidebarWidth,
      color: isDark ? const Color(0xFF0D1117) : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Logo / Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'ᱚ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Olitun',
                  style: AppTypography.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nav Items
          SidebarNavItem(
            icon: Icons.school_rounded,
            label: l10n.navLearn,
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            isDark: isDark,
          ),
          SidebarNavItem(
            icon: Icons.music_note_rounded,
            label: l10n.navBakhed,
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
            isDark: isDark,
          ),
          SidebarNavItem(
            icon: Icons.person_rounded,
            label: l10n.navProfile,
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            isDark: isDark,
          ),

          const Spacer(),

          // Dark/Light Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.04,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrentlyDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.amber.shade300
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCurrentlyDark ? l10n.dark : l10n.light,
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: isCurrentlyDark,
                      onChanged: (val) {
                        updateThemeMode(ref, val ? 'dark' : 'light');
                      },
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      inactiveThumbColor: Colors.orange.shade400,
                      inactiveTrackColor: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : hovered
                      ? (widget.isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.04)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isActive
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 22,
                      color: isActive
                          ? AppColors.primary
                          : widget.isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.label,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : widget.isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    if (isActive) ...[
                      const Spacer(),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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
