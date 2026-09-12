import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

class RhymeSegmentedControl extends StatelessWidget {
  const RhymeSegmentedControl({
    super.key,
    required this.isDark,
    required this.isTablet,
    required this.currentTab,
    required this.onTabSelect,
  });

  final bool isDark;
  final bool isTablet;
  final int currentTab;
  final ValueChanged<int> onTabSelect;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: 12,
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: currentTab == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      icon: Icons.music_note_rounded,
                      label: 'Bakhed Audio',
                      selected: currentTab == 0,
                      isDark: isDark,
                      onTap: () => onTabSelect(0),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      icon: Icons.school_rounded,
                      label: 'Binti Guru',
                      selected: currentTab == 1,
                      isDark: isDark,
                      onTap: () => onTabSelect(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
    );
  }
}

/// One tab of the segmented control. A single builder guarantees both
/// labels share identical structure, padding, and optical alignment: the
/// icon lives in a fixed box (absorbing glyph optical-center differences)
/// and the label uses a fixed line height.
class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black54);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(child: Icon(icon, size: 16, color: contentColor)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
