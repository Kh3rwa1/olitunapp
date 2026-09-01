import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/admin_failure.dart';
import 'admin_buttons.dart';

/// Comprehensive, safety-hardened dialog for destructive & consequential operations.
class AdminDestructiveDialog extends StatefulWidget {
  const AdminDestructiveDialog({
    super.key,
    required this.title,
    required this.actionName,
    required this.targetName,
    required this.blastRadiusDescription,
    this.affectedCount,
    this.isReversible = false,
    this.requiresTypedConfirmation = false,
    this.typedConfirmationKeyword = 'CONFIRM',
    this.confirmButtonLabel = 'Execute Action',
    this.cancelButtonLabel = 'Cancel',
    this.icon = Icons.warning_amber_rounded,
    this.isDanger = true,
    required this.onConfirm,
  });

  final String title;
  final String actionName;
  final String targetName;
  final String blastRadiusDescription;
  final int? affectedCount;
  final bool isReversible;
  final bool requiresTypedConfirmation;
  final String typedConfirmationKeyword;
  final String confirmButtonLabel;
  final String cancelButtonLabel;
  final IconData icon;
  final bool isDanger;
  final Future<void> Function() onConfirm;

  /// Shows the modal dialog and returns true if operation completed successfully.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String actionName,
    required String targetName,
    required String blastRadiusDescription,
    int? affectedCount,
    bool isReversible = false,
    bool requiresTypedConfirmation = false,
    String typedConfirmationKeyword = 'CONFIRM',
    String confirmButtonLabel = 'Execute Action',
    String cancelButtonLabel = 'Cancel',
    IconData icon = Icons.warning_amber_rounded,
    bool isDanger = true,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminDestructiveDialog(
        title: title,
        actionName: actionName,
        targetName: targetName,
        blastRadiusDescription: blastRadiusDescription,
        affectedCount: affectedCount,
        isReversible: isReversible,
        requiresTypedConfirmation: requiresTypedConfirmation,
        typedConfirmationKeyword: typedConfirmationKeyword,
        confirmButtonLabel: confirmButtonLabel,
        cancelButtonLabel: cancelButtonLabel,
        icon: icon,
        isDanger: isDanger,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AdminDestructiveDialog> createState() => _AdminDestructiveDialogState();
}

class _AdminDestructiveDialogState extends State<AdminDestructiveDialog> {
  final TextEditingController _typedInputController = TextEditingController();
  bool _isExecuting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _typedInputController.dispose();
    super.dispose();
  }

  bool get _isTypedConfirmed {
    if (!widget.requiresTypedConfirmation) return true;
    return _typedInputController.text.trim() == widget.typedConfirmationKeyword;
  }

  Future<void> _handleConfirm() async {
    if (_isExecuting || !_isTypedConfirmed) return;

    setState(() {
      _isExecuting = true;
      _errorMessage = null;
    });
    HapticFeedback.heavyImpact();

    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final failure = AdminFailure.fromException(
          e,
          actionContext: widget.actionName,
        );
        setState(() {
          _isExecuting = false;
          _errorMessage = failure.userMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.isDanger ? AppColors.error : AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AdminTokens.overlay(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
            border: Border.all(
              color: widget.isDanger
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AdminTokens.border(isDark),
            ),
            boxShadow: AdminTokens.overlayShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.16 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.35 : 0.25,
                        ),
                      ),
                    ),
                    child: Icon(widget.icon, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AdminTokens.sectionTitle(isDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Action: ${widget.actionName}',
                          style: AdminTokens.label(isDark).copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Target & Blast Radius details panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminTokens.sunken(isDark),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  border: Border.all(color: AdminTokens.border(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: ',
                          style: AdminTokens.bodyStrong(
                            isDark,
                          ).copyWith(fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            widget.targetName,
                            style: AdminTokens.body(
                              isDark,
                            ).copyWith(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    if (widget.affectedCount != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Affected items: ',
                            style: AdminTokens.bodyStrong(
                              isDark,
                            ).copyWith(fontSize: 12),
                          ),
                          Expanded(
                            child: Text(
                              '${widget.affectedCount}',
                              style: AdminTokens.body(isDark).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Reversibility: ',
                          style: AdminTokens.bodyStrong(
                            isDark,
                          ).copyWith(fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            widget.isReversible
                                ? 'Reversible'
                                : 'Irreversible (Cannot be undone)',
                            style: AdminTokens.body(isDark).copyWith(
                              fontSize: 12,
                              color: widget.isReversible
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: AdminTokens.divider(isDark)),
                    const SizedBox(height: 8),
                    Text(
                      widget.blastRadiusDescription,
                      style: AdminTokens.body(
                        isDark,
                      ).copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              // Typed confirmation input if required
              if (widget.requiresTypedConfirmation) ...[
                const SizedBox(height: 16),
                Text(
                  'To confirm, please type "${widget.typedConfirmationKeyword}" below:',
                  style: AdminTokens.label(
                    isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _typedInputController,
                  enabled: !_isExecuting,
                  autofocus: true,
                  style: TextStyle(
                    color: AdminTokens.textPrimary(isDark),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.typedConfirmationKeyword,
                    hintStyle: TextStyle(color: AdminTokens.textMuted(isDark)),
                    filled: true,
                    fillColor: AdminTokens.sunken(isDark),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      borderSide: BorderSide(color: AdminTokens.border(isDark)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              // Error banner if execution failed
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: widget.cancelButtonLabel,
                      onTap: _isExecuting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isExecuting || !_isTypedConfirmed)
                          ? null
                          : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusMd,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isExecuting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.confirmButtonLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
    );
  }
}
