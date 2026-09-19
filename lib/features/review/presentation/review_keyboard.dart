// Lightweight Ol Chiki keyboard for review typing cards.
//
// The existing OlChikiKeyboard is coupled to TypingPracticeController (stars
// + its own analytics). Review typing needs the same keys driving local
// session state + the memory scheduler instead, so this widget renders the
// same verified key layout with plain callbacks. No new keys invented.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ReviewKeyboard extends StatelessWidget {
  final void Function(String char) onKey;
  final VoidCallback onDelete;
  final bool showDigits;

  const ReviewKeyboard({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.showDigits = false,
  });

  static const List<String> vowels = ['ᱚ', 'ᱟ', 'ᱤ', 'ᱩ', 'ᱮ', 'ᱳ'];
  static const List<String> consonantsR1 = ['ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱠ', 'ᱡ'];
  static const List<String> consonantsR2 = ['ᱢ', 'ᱣ', 'ᱥ', 'ᱦ', 'ᱧ', 'ᱨ'];
  static const List<String> consonantsR3 = ['ᱪ', 'ᱫ', 'ᱬ', 'ᱭ', 'ᱯ', 'ᱰ'];
  static const List<String> consonantsR4 = ['ᱱ', 'ᱲ', 'ᱴ', 'ᱵ', 'ᱶ', 'ᱷ'];
  // Otted / modifier marks (U+1C78–U+1C7D) — same set as OlChikiKeyboard.
  static const List<String> marks = ['ᱸ', 'ᱹ', 'ᱺ', 'ᱻ', 'ᱼ', 'ᱽ'];
  static const List<String> digits = [
    '᱐',
    '᱑',
    '᱒',
    '᱓',
    '᱔',
    '᱕',
    '᱖',
    '᱗',
    '᱘',
    '᱙',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = <List<String>>[
      vowels,
      consonantsR1,
      consonantsR2,
      consonantsR3,
      consonantsR4,
      marks,
      if (showDigits) digits,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final char in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: _Key(
                      label: char,
                      isDark: isDark,
                      onTap: () => onKey(char),
                    ),
                  ),
                ),
            ],
          ),
        ],
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _Key(
                  label: 'space',
                  icon: Icons.space_bar_rounded,
                  isDark: isDark,
                  onTap: () => onKey(' '),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _Key(
                  label: 'delete',
                  icon: Icons.backspace_outlined,
                  isDark: isDark,
                  onTap: onDelete,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isDark;
  final VoidCallback onTap;

  const _Key({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.white70 : AppColors.primaryDark,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
