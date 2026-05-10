import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import 'admin_buttons.dart';

/// Tokenised loading state — centered spinner with a label.
class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AdminTokens.accent),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(
              label!,
              style: AdminTokens.label(
                isDark,
              ).copyWith(color: AdminTokens.textSecondary(isDark)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tokenised error state — icon, message, optional retry.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AdminTokens.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: AdminTokens.space5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTokens.sectionTitle(isDark),
              ),
              const SizedBox(height: AdminTokens.space2),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: AdminTokens.body(
                  isDark,
                ).copyWith(color: AdminTokens.textSecondary(isDark)),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AdminTokens.space5),
                AdminPrimaryButton(
                  label: 'Try again',
                  onTap: onRetry!,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
