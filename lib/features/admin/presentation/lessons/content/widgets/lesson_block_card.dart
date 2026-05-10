import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../../shared/widgets/gamified_card.dart';

class LessonBlockCard extends StatelessWidget {
  final int index;
  final LessonBlockEntity block;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LessonBlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (block.type) {
      case 'text':
        icon = Icons.text_fields_rounded;
        color = Colors.blue;
        title = 'Text Block';
        subtitle = block.textLatin ?? block.textOlChiki ?? 'Empty text block';
        break;
      case 'image':
        icon = Icons.image_rounded;
        color = AppColors.duoBlue;
        title = 'Image Block';
        subtitle = block.imageUrl ?? 'No image selected';
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        color = Colors.orange;
        title = 'Audio Block';
        subtitle = block.audioUrl ?? 'No audio selected';
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        color = Colors.purple;
        title = 'Video Block';
        subtitle = block.audioUrl ?? 'No video selected'; // Using audioUrl as per data model
        break;
      case 'lottie':
        icon = Icons.animation_rounded;
        color = const Color(0xFF10B981);
        title = 'Lottie Animation';
        subtitle = block.data?['animationUrl'] ?? 'No animation selected';
        break;
      case 'quiz':
        icon = Icons.quiz_rounded;
        color = Colors.green;
        title = 'Quiz Block';
        subtitle = 'Quiz Ref: ${block.data?['quizRefId'] ?? "None"}';
        break;
      default:
        icon = Icons.extension;
        color = Colors.grey;
        title = 'Unknown Block';
        subtitle = block.type;
    }

    return GamifiedCard(
      borderRadius: AdminTokens.radiusLg,
      color: AdminTokens.raised(isDark),
      padding: const EdgeInsets.all(0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: isDark ? Colors.white70 : Colors.black54,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Colors.red[400],
              onPressed: onDelete,
            ),
            Icon(
              Icons.drag_handle_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}
