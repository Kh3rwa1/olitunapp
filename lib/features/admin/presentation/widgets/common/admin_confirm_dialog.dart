import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import 'admin_buttons.dart';

/// Tokenised confirmation dialog (delete / destructive flows).
Future<bool?> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool destructive = true,
  IconData icon = Icons.delete_outline_rounded,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AdminTokens.overlay(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
            border: Border.all(color: AdminTokens.border(isDark)),
            boxShadow: AdminTokens.overlayShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: destructive
                          ? AppColors.error.withValues(alpha: 0.14)
                          : AdminTokens.accentSoft(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: destructive ? AppColors.error : AdminTokens.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title, style: AdminTokens.sectionTitle(isDark)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: AdminTokens.body(isDark).copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: cancelLabel,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, true);
                        },
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: destructive
                                ? AppColors.error
                                : AdminTokens.accent,
                            borderRadius: BorderRadius.circular(
                              AdminTokens.radiusMd,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
