import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';

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
