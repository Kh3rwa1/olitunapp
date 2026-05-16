import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';

class ActivityRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActivityRow({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AdminTokens.label(isDark).copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                  color: AdminTokens.textTertiary(isDark),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AdminTokens.textMuted(isDark),
        ),
      ],
    );
  }
}

String formatRelative(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
