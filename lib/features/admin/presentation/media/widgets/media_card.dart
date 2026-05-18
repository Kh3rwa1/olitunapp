import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../admin_media_state.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onCopyUrl;

  const MediaCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onDelete,
    required this.onCopyUrl,
  });

  IconData _getIcon() {
    switch (item.type) {
      case MediaType.image:
        return Icons.image_rounded;
      case MediaType.audio:
        return Icons.audiotrack_rounded;
      case MediaType.video:
        return Icons.videocam_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColor() {
    switch (item.type) {
      case MediaType.image:
        return AdminTokens.accent;
      case MediaType.audio:
        return AppColors.accentPurple;
      case MediaType.video:
        return AppColors.accentCoral;
      default:
        return AppColors.accentCyan;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getColor();
    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AdminTokens.radiusLg),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(_getIcon(), size: 30, color: accent),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AdminTokens.overlay(isDark),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusXs,
                          ),
                          border: Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: AdminTokens.textSecondary(isDark),
                        ),
                      ),
                      color: AdminTokens.overlay(isDark),
                      onSelected: (value) {
                        if (value == 'copy') onCopyUrl();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Copy URL'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTokens.bodyStrong(isDark),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(item.size),
                  style: AdminTokens.label(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
