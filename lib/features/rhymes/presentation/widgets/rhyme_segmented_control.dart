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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabSelect(0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 16,
                            color: currentTab == 0
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bakhed Audio',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: currentTab == 0
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabSelect(1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 16,
                            color: currentTab == 1
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Binti Guru',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: currentTab == 1
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
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
