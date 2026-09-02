import 'package:flutter/material.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

class AdminLessonBlocksNeedEditingState extends StatelessWidget {
  const AdminLessonBlocksNeedEditingState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.isDark,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final bool isDark;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AdminTokens.raised(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
            border: Border.all(color: AdminTokens.border(isDark)),
            boxShadow: AdminTokens.raisedShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTokens.cardTitle(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AdminTokens.body(isDark).copyWith(
                  color: AdminTokens.textSecondary(isDark),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
