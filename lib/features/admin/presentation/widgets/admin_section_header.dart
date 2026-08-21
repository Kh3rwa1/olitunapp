import 'package:flutter/material.dart';
import '../../../../core/theme/admin_tokens.dart';

/// Refined page header used at the top of every admin screen.
///
/// Composes a subtle eyebrow ("ADMIN · CATEGORIES"), a real display-scale
/// title, and an optional supporting subtitle. Icon treatment is restrained —
/// a small accent chip rather than a giant gradient tile — so the title is
/// clearly the focal point.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final IconData? icon;
  final String? eyebrow;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.icon,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eyebrowText = (eyebrow ?? title).toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 600;
        final isWide = width > 760;

        final titleStyle = compact
            ? AdminTokens.pageTitle(isDark).copyWith(fontSize: 24)
            : AdminTokens.display(isDark);

        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: compact ? 40 : 48,
                      height: compact ? 40 : 48,
                      decoration: BoxDecoration(
                        color: AdminTokens.accentSoft(isDark),
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: AdminTokens.accentBorder(isDark),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: AdminTokens.accent,
                        size: compact ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: compact ? 12 : 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AdminTokens.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'ADMIN · $eyebrowText',
                                overflow: TextOverflow.ellipsis,
                                style: AdminTokens.eyebrow(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(title, style: titleStyle),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AdminTokens.body(
                              isDark,
                            ).copyWith(fontSize: compact ? 12 : 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty && isWide) ...[
                    const SizedBox(width: 16),
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: actions!,
                      ),
                    ),
                  ],
                ],
              ),
              if (actions != null && actions!.isNotEmpty && !isWide) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
