import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// Tokenised text field used across all admin forms.
class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? helperText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTokens.label(isDark)),
        const SizedBox(height: AdminTokens.space2),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AdminTokens.bodyStrong(isDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AdminTokens.body(
              isDark,
            ).copyWith(color: AdminTokens.textTertiary(isDark)),
            filled: true,
            fillColor: AdminTokens.sunken(isDark),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 20,
                    color: AdminTokens.textTertiary(isDark),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              borderSide: BorderSide(color: AdminTokens.border(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              borderSide: BorderSide(color: AdminTokens.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              borderSide: const BorderSide(
                color: AdminTokens.accent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AdminTokens.label(
              isDark,
            ).copyWith(color: AdminTokens.textTertiary(isDark)),
          ),
        ],
      ],
    );
  }
}

/// Modal sheet shell with drag handle, header (icon + title + close),
/// scrollable body, and a footer (Cancel / Primary). Tokenised.
class AdminModalSheet extends StatelessWidget {
  const AdminModalSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.cancelLabel = 'Cancel',
    this.heightFactor = 0.85,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String cancelLabel;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminTokens.accentSoft(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                      border: Border.all(
                        color: AdminTokens.accentBorder(isDark),
                      ),
                    ),
                    child: Icon(icon, color: AdminTokens.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AdminTokens.sectionTitle(isDark)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AdminTokens.label(
                            isDark,
                          ).copyWith(color: AdminTokens.textTertiary(isDark)),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AdminTokens.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AdminTokens.baseTint(isDark),
              border: Border(
                top: BorderSide(color: AdminTokens.divider(isDark)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: cancelLabel,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AdminPrimaryButton(
                      label: primaryLabel,
                      onTap: onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
