import 'package:flutter/material.dart';

import 'package:itun/core/theme/app_colors.dart';

class ContentBulkActionBar extends StatelessWidget {
  final bool isDark;
  final int selectedCount;
  final bool allSelected;
  final bool supportsPublished;
  final ValueChanged<bool?> onToggleSelectAll;
  final VoidCallback onBulkPublish;
  final VoidCallback onBulkDraft;
  final VoidCallback onBulkDelete;

  const ContentBulkActionBar({
    super.key,
    required this.isDark,
    required this.selectedCount,
    required this.allSelected,
    required this.supportsPublished,
    required this.onToggleSelectAll,
    required this.onBulkPublish,
    required this.onBulkDraft,
    required this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Semantics(
              label: 'Select all filtered items',
              checked: allSelected,
              child: Checkbox(
                value: allSelected,
                activeColor: AppColors.primary,
                onChanged: onToggleSelectAll,
              ),
            ),
            Text(
              '$selectedCount items selected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (supportsPublished) ...[
              ElevatedButton.icon(
                onPressed: onBulkPublish,
                icon: const Icon(Icons.publish_rounded, size: 16),
                label: const Text('Publish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onBulkDraft,
                icon: const Icon(Icons.unpublished_rounded, size: 16),
                label: const Text('Draft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: onBulkDelete,
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
