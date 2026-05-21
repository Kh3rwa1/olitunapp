import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminSettingsSectionCard extends StatelessWidget {
  const AdminSettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDanger
        ? AppColors.error.withValues(alpha: 0.35)
        : AdminTokens.border(isDark);
    final accentColor = isDanger ? AppColors.error : AdminTokens.accent;
    final accentSoftColor = isDanger
        ? AppColors.error.withValues(alpha: isDark ? 0.14 : 0.10)
        : AdminTokens.accentSoft(isDark);
    final accentBorderColor = isDanger
        ? AppColors.error.withValues(alpha: isDark ? 0.34 : 0.28)
        : AdminTokens.accentBorder(isDark);

    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: borderColor),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentSoftColor,
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(color: accentBorderColor),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTokens.sectionTitle(isDark)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AdminTokens.body(isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDanger ? borderColor : AdminTokens.divider(isDark),
          ),
          child,
        ],
      ),
    );
  }
}
