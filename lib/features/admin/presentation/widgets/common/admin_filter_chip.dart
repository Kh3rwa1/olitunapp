import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';

/// Tokenised filter pill (selected = accent, idle = sunken).
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AdminTokens.accent : AdminTokens.sunken(isDark),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AdminTokens.accent : AdminTokens.border(isDark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : AdminTokens.textSecondary(isDark),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: selected
                      ? Colors.white
                      : AdminTokens.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
