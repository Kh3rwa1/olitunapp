import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../categories/domain/entities/category_entity.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/utils/media_type_resolver.dart';

class LessonCard extends ConsumerWidget {
  final LessonEntity lesson;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoryNotifierProvider).value ?? <CategoryEntity>[];
    final category = categories
        .where((c) => c.id == lesson.categoryId)
        .firstOrNull;
    final categoryName = category?.titleLatin ?? 'Uncategorized';

    final blockCount = lesson.blocks.length;
    final hasBlocks = blockCount > 0;
    final mediaUrl =
        lesson.data?['heroMediaUrl'] as String? ??
        lesson.data?['thumbnailUrl'] as String?;
    final posterUrl = lesson.data?['heroPosterUrl'] as String?;
    final isWide = MediaQuery.of(context).size.width > 800;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/admin/lessons/content/${lesson.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Thumbnail or Icon
                      _buildThumbnail(mediaUrl, posterUrl),
                      const SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            _buildCategoryBadge(categoryName),
                            const SizedBox(height: 6),

                            // Title (Latin — human readable)
                            Text(
                              lesson.titleLatin.isNotEmpty
                                  ? lesson.titleLatin
                                  : lesson.titleOlChiki,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Ol Chiki subtitle
                            if (lesson.titleOlChiki.isNotEmpty &&
                                lesson.titleLatin.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  lesson.titleOlChiki,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Metadata chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildChip(
                                  icon: Icons.layers_rounded,
                                  label:
                                      '$blockCount block${blockCount != 1 ? 's' : ''}',
                                  color: hasBlocks
                                      ? AppColors.primary
                                      : AppColors.error,
                                  isDark: isDark,
                                ),
                                _buildChip(
                                  icon: Icons.timer_outlined,
                                  label: '${lesson.estimatedMinutes} min',
                                  color: const Color(0xFF6366F1),
                                  isDark: isDark,
                                ),
                                if (!lesson.isActive)
                                  _buildChip(
                                    icon: Icons.visibility_off_rounded,
                                    label: 'Hidden',
                                    color: Colors.orange,
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (isWide) const SizedBox(width: 8),
                    ],
                  ),
                ),

                // Action bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Edit Details',
                        onTap: onEdit,
                        isMobile: isMobile,
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Manage Content',
                        onTap: () =>
                            context.go('/admin/lessons/content/${lesson.id}'),
                        isPrimary: true,
                        isMobile: isMobile,
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        onTap: onDelete,
                        isDestructive: true,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? mediaUrl, String? posterUrl) {
    final url = mediaUrl?.trim();
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: url == null || url.isEmpty ? AppColors.premiumCyan : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? _buildMediaPreview(url, posterUrl)
          : _buildIconFallback(),
    );
  }

  Widget _buildMediaPreview(String url, String? posterUrl) {
    switch (MediaTypeResolver.resolve(url)) {
      case MediaKind.video:
        if (posterUrl != null && posterUrl.trim().isNotEmpty) {
          return Image.network(
            posterUrl.trim(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildMediaIcon(Icons.movie_rounded),
          );
        }
        return _buildMediaIcon(Icons.play_circle_fill_rounded);
      case MediaKind.lottie:
        return Lottie.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildMediaIcon(Icons.animation_rounded),
        );
      case MediaKind.svg:
      case MediaKind.image:
      case MediaKind.html:
      case MediaKind.audio:
      case MediaKind.unknown:
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildMediaIcon(
            MediaTypeResolver.resolve(url) == MediaKind.html
                ? Icons.code_rounded
                : Icons.image_rounded,
          ),
        );
    }
  }

  Widget _buildMediaIcon(IconData icon) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.premiumCyan),
      child: Center(child: Icon(icon, color: Colors.white, size: 26)),
    );
  }

  Widget _buildIconFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.premiumCyan),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCategoryBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        name.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
    bool isMobile = false,
  }) {
    final color = isDestructive
        ? AppColors.error
        : isPrimary
        ? AppColors.primary
        : (isDark ? Colors.white54 : Colors.black45);

    if (isMobile) {
      return IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
