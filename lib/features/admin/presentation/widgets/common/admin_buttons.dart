import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

/// Solid accent primary action button used in modal footers / page headers.
class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 11 : 14,
          ),
          decoration: BoxDecoration(
            color: AdminTokens.accent,
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            boxShadow: AdminTokens.brandGlow(AdminTokens.accent, strength: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: compact ? 16 : 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outline / ghost secondary action button.
class AdminSecondaryButton extends StatelessWidget {
  const AdminSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = destructive
        ? AppColors.error
        : AdminTokens.textPrimary(isDark);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.error.withValues(alpha: isDark ? 0.14 : 0.10)
                : AdminTokens.sunken(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            border: Border.all(
              color: destructive
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AdminTokens.border(isDark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon button used inside cards (edit / delete).
class AdminIconAction extends StatelessWidget {
  const AdminIconAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = destructive
        ? AppColors.error
        : AdminTokens.textSecondary(isDark);
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.error.withValues(alpha: isDark ? 0.12 : 0.08)
                : AdminTokens.sunken(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            border: Border.all(
              color: destructive
                  ? AppColors.error.withValues(alpha: 0.22)
                  : AdminTokens.border(isDark),
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
