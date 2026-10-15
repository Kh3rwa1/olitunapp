import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itun/core/theme/app_typography.dart';

import '../../../../../core/theme/app_colors.dart';

/// Lyrics / Vocabulary / Notes switcher; tabs without content are hidden.
class PremiumBakhedSubTabsBar extends StatelessWidget {
  const PremiumBakhedSubTabsBar({
    super.key,
    required this.activeSubTab,
    required this.onSelect,
    required this.hasLyrics,
    required this.hasVocab,
    required this.hasNotes,
    this.isCompact = false,
  });

  final int activeSubTab;
  final ValueChanged<int> onSelect;
  final bool hasLyrics;
  final bool hasVocab;
  final bool hasNotes;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[];

    if (hasLyrics) {
      tabs.add(
        Expanded(
          child: _PremiumBakhedSubTabButton(
            index: 0,
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            activeSubTab: activeSubTab,
            onSelect: onSelect,
            isCompact: isCompact,
          ),
        ),
      );
    }
    if (hasVocab) {
      tabs.add(
        Expanded(
          child: _PremiumBakhedSubTabButton(
            index: 1,
            icon: Icons.menu_book_rounded,
            label: 'Vocabulary',
            activeSubTab: activeSubTab,
            onSelect: onSelect,
            isCompact: isCompact,
          ),
        ),
      );
    }
    if (hasNotes) {
      tabs.add(
        Expanded(
          child: _PremiumBakhedSubTabButton(
            index: 2,
            icon: Icons.auto_stories_rounded,
            label: 'Notes',
            activeSubTab: activeSubTab,
            onSelect: onSelect,
            isCompact: isCompact,
          ),
        ),
      );
    }

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: isCompact ? 46 : 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: tabs),
    );
  }
}

class _PremiumBakhedSubTabButton extends StatelessWidget {
  const _PremiumBakhedSubTabButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.activeSubTab,
    required this.onSelect,
    this.isCompact = false,
  });

  final int index;
  final IconData icon;
  final String label;
  final int activeSubTab;
  final ValueChanged<int> onSelect;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isSelected = activeSubTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelect(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isSelected ? AppColors.primary : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
