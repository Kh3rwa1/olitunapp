import 'package:flutter/material.dart';

import '../../../../core/theme/admin_tokens.dart';

/// Tokenised page header used by full-screen admin pages that don't
/// (yet) embed [AdminSectionHeader]. Mirrors the dashboard / login type
/// scale: optional eyebrow, accent rail, display title, and a muted
/// supporting line.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 4,
          height: subtitle == null ? 28 : 44,
          decoration: BoxDecoration(
            color: AdminTokens.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    eyebrow!.toUpperCase(),
                    style: AdminTokens.eyebrow(
                      isDark,
                    ).copyWith(color: AdminTokens.accent),
                  ),
                ),
              Text(title, style: AdminTokens.pageTitle(isDark)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AdminTokens.body(
                    isDark,
                  ).copyWith(color: AdminTokens.textSecondary(isDark)),
                ),
              ],
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Wrap(spacing: 8, children: actions!),
        ],
      ],
    );
  }
}
