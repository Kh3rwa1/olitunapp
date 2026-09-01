import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../domain/content_badge_resolver.dart';
import '../../../../presentation/widgets/content_type_badge.dart';
import 'lesson_block_preview.dart';
import '../../../../../../../shared/models/content_item.dart';

class LessonBlockCard extends StatelessWidget {
  final int index;
  final LessonBlockEntity block;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final String? categoryId;
  final String? categorySlug;

  const LessonBlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.categoryId,
    this.categorySlug,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;

    switch (block.type) {
      case 'text':
        icon = Icons.text_fields_rounded;
        color = Colors.blue;
        title = 'Text Block';
        break;
      case 'image':
        icon = Icons.image_rounded;
        color = AppColors.brandBlue;
        title = 'Image Block';
        break;
      case 'svg':
        icon = Icons.polyline_rounded;
        color = const Color(0xFF0EA5E9);
        title = 'SVG Block';
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        color = Colors.orange;
        title = 'Audio Block';
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        color = Colors.purple;
        title = 'Video Block';
        break;
      case 'lottie':
        icon = Icons.animation_rounded;
        color = const Color(0xFF10B981);
        title = 'Lottie Animation';
        break;
      case 'quiz':
        icon = Icons.quiz_rounded;
        color = Colors.green;
        title = 'Quiz Block';
        break;
      case 'glyph':
        icon = Icons.abc_rounded;
        color = const Color(0xFFEC4899);
        title = 'Glyph Block';
        break;
      case 'callout':
        icon = Icons.lightbulb_rounded;
        color = const Color(0xFFF59E0B);
        title = 'Callout Block';
        break;
      case 'tracing':
        icon = Icons.gesture_rounded;
        color = const Color(0xFF14B8A6);
        title = 'Tracing Block';
        break;
      default:
        icon = Icons.extension;
        color = Colors.grey;
        title = 'Unknown Block';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Controls & Metadata)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                ContentTypeBadge(
                  type: resolveBadgeType(
                    kind: ContentKind.lesson,
                    categoryId: categoryId,
                    categorySlug: categorySlug,
                    blockType: block.type,
                  ),
                  size: 24,
                ),
                const SizedBox(width: 8),
                // Block Type Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '#${index + 1} • $title',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Actions (Edit, Delete, Drag Handle)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: isDark ? Colors.white70 : Colors.black54,
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit details',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Colors.red[400],
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete block',
                ),
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: 'Drag to reorder',
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Block Content Live Visual Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: LessonBlockPreview(block: block, isDark: isDark),
          ),
        ],
      ),
    );
  }
}
