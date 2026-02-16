import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final IconData? icon;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    // Adaptive sizing
    final titleSize = (width < 600) ? 28.0 : (width < 1100 ? 32.0 : 40.0);
    final iconSize = (width < 600) ? 24.0 : 28.0;

    return Padding(
      padding: EdgeInsets.only(bottom: width < 600 ? 24 : 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(width < 600 ? 10 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: iconSize),
                  ),
                  SizedBox(height: width < 600 ? 12 : 16),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: width < 600 ? -0.5 : -1.5,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: width < 600 ? 14 : 16,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty && width > 400) ...[
            const SizedBox(width: 24),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}
