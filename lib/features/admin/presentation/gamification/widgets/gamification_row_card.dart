import 'package:flutter/material.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import '../models/gamification_section.dart';
import 'gamification_widgets.dart';

class GamificationRowCard extends StatelessWidget {
  const GamificationRowCard({
    super.key,
    required this.section,
    required this.row,
    required this.onPreview,
    required this.onEdit,
    required this.onPublish,
    required this.onUnpublish,
    required this.onArchive,
  });

  final GamificationSection section;
  final Map<String, dynamic> row;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onArchive;

  String _titleFor(Map<String, dynamic> row, GamificationSection section) {
    for (final key in ['title', 'name', section.idField, 'action']) {
      final value = row[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return row['id']?.toString() ?? 'Untitled';
  }

  String _subtitleFor(Map<String, dynamic> row) {
    for (final key in [
      'body',
      'description',
      'subtitle',
      'meaning',
      'latin',
      'olChiki',
      'trigger',
      'type',
      'sourceId',
    ]) {
      final value = row[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return '';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'published' => AppColors.success,
      'archived' => Colors.blueGrey,
      'draft' => AppColors.duoOrange,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _titleFor(row, section);
    final subtitle = _subtitleFor(row);
    final status = row['status']?.toString() ?? '';
    final active = row['isActive'] == true;
    final supportsStatus = section.editableFields.contains('status');
    final supportsPublish =
        supportsStatus || section.collectionId == 'bakhed_cultural_notes';

    return Card(
      elevation: 0,
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTokens.accentSoft(isDark),
                  child: Icon(section.icon, color: AdminTokens.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTokens.cardTitle(isDark)),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTokens.body(isDark),
                        ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  StatusPill(label: status, color: _statusColor(status)),
                if (active) ...[
                  const SizedBox(width: 8),
                  const StatusPill(label: 'active', color: AppColors.success),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Preview'),
                ),
                if (!section.readOnly)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                if (!section.readOnly && supportsPublish)
                  OutlinedButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.publish_rounded, size: 16),
                    label: const Text('Publish'),
                  ),
                if (!section.readOnly && supportsPublish)
                  OutlinedButton.icon(
                    onPressed: onUnpublish,
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: const Text('Unpublish'),
                  ),
                if (!section.readOnly && supportsStatus)
                  OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_rounded, size: 16),
                    label: const Text('Archive'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
