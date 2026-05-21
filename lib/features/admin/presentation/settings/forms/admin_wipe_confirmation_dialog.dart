import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_form_widgets.dart';

class AdminWipeConfirmationDialog extends StatefulWidget {
  const AdminWipeConfirmationDialog({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<AdminWipeConfirmationDialog> createState() =>
      _AdminWipeConfirmationDialogState();
}

class _AdminWipeConfirmationDialogState
    extends State<AdminWipeConfirmationDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = _textController.text.trim() == 'WIPE ALL';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AdminTokens.overlay(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
          boxShadow: AdminTokens.overlayShadow(isDark),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you absolutely sure?',
                        style: AdminTokens.cardTitle(
                          isDark,
                        ).copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Destructive Action',
                        style: AdminTokens.eyebrow(
                          isDark,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'This action will permanently delete all categorized content, lessons, words, sentences, and quizzes across all database collections, clear all client local storage content caches, and trigger a complete fresh seeding procedure.',
              style: AdminTokens.body(isDark),
            ),
            const SizedBox(height: 20),
            Text(
              'Please type "WIPE ALL" in the box below to authorize this procedure:',
              style: AdminTokens.bodyStrong(isDark),
            ),
            const SizedBox(height: 12),
            AdminTextField(
              controller: _textController,
              label: 'Authorization Key',
              hint: 'WIPE ALL',
              prefixIcon: Icons.vpn_key_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminSecondaryButton(
                  label: 'Cancel',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled
                        ? () {
                            Navigator.of(context).pop();
                            widget.onConfirm();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    child: Opacity(
                      opacity: isEnabled ? 1.0 : 0.45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusMd,
                          ),
                          boxShadow: isEnabled
                              ? AdminTokens.brandGlow(
                                  AppColors.error,
                                  strength: 0.7,
                                )
                              : null,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'WIPE ALL & RE-SEED',
                              style: TextStyle(
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
