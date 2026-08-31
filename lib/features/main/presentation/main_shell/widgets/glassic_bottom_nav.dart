import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/minimum_tap_target.dart';

class GlassicBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isDark;
  final bool isTablet;

  const GlassicBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isDark,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 32 : 24,
        0,
        isTablet ? 32 : 24,
        MediaQuery.of(context).viewPadding.bottom + (isTablet ? 20 : 15),
      ),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.15,
                ),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.school_rounded, 'Learn'),
                _buildNavItem(1, Icons.music_note_rounded, 'Bakhed'),
                _buildNavItem(2, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 800.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;

    return MinimumTapTarget(
      onTap: () {
        onItemTapped(index);
        HapticFeedback.lightImpact();
      },
      selected: isSelected,
      semanticLabel: '$label tab',
      borderRadius: BorderRadius.circular(20),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
                  duration: 400.ms,
                  padding: const EdgeInsets.all(10),
                  curve: Curves.easeOutBack,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white54 : Colors.black45),
                    size: isSelected ? 30 : 26,
                  ),
                )
                .animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
