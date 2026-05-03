import 'package:flutter/material.dart';

import '../../../../core/theme/admin_tokens.dart';

/// Tokenised, on-brand empty state used by every admin content screen.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    this.icon,
    this.glyph,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || glyph != null,
            'Provide either an icon or a glyph.');

  final IconData? icon;
  final String? glyph;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget mark = glyph != null
        ? Text(
            glyph!,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AdminTokens.accent,
              height: 1,
            ),
          )
        : Icon(icon, size: 38, color: AdminTokens.accent);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AdminTokens.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AdminTokens.accentSoft(isDark),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
                  border: Border.all(
                    color: AdminTokens.accentBorder(isDark),
                  ),
                ),
                alignment: Alignment.center,
                child: mark,
              ),
              const SizedBox(height: AdminTokens.space6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTokens.sectionTitle(isDark),
              ),
              if (message != null) ...[
                const SizedBox(height: AdminTokens.space2),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AdminTokens.body(isDark).copyWith(
                    color: AdminTokens.textSecondary(isDark),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AdminTokens.space6),
                _EmptyAction(label: actionLabel!, onTap: onAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AdminTokens.accent,
            borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
            boxShadow: AdminTokens.brandGlow(AdminTokens.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
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
