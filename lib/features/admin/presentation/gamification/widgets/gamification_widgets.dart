import 'package:flutter/material.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import '../models/gamification_section.dart';

class GamificationOverviewCard extends StatelessWidget {
  const GamificationOverviewCard({
    super.key,
    required this.section,
    required this.onTap,
  });

  final GamificationSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTokens.border(isDark)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AdminTokens.accentSoft(isDark),
              child: Icon(section.icon, color: AdminTokens.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AdminTokens.cardTitle(isDark)),
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTokens.body(isDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class OpsMetricCard extends StatelessWidget {
  const OpsMetricCard({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: AdminTokens.accent,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AdminTokens.body(isDark),
          ),
        ],
      ),
    );
  }
}

class GamificationPreviewCard extends StatelessWidget {
  const GamificationPreviewCard({
    super.key,
    required this.label,
    required this.row,
    required this.dark,
  });

  final String label;
  final Map<String, dynamic> row;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final title =
        row['title']?.toString() ??
        row['name']?.toString() ??
        row['rewardLabel']?.toString() ??
        'Preview';
    final body =
        row['body']?.toString() ??
        row['description']?.toString() ??
        row['subtitle']?.toString() ??
        'No preview copy yet.';
    final icon = row['icon']?.toString() ?? '🌱';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
