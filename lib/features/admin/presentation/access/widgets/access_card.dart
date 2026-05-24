import 'package:flutter/material.dart';
import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';

class AccessCard extends StatelessWidget {
  const AccessCard({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTokens.cardTitle(isDark)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AdminTokens.body(
                        isDark,
                      ).copyWith(color: AdminTokens.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
