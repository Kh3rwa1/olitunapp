import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/admin/presentation/widgets/admin_form_widgets.dart';
import 'package:itun/features/admin/presentation/widgets/content_type_badge.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/widgets/cover_thumbnail.dart';

class ContentListTile extends StatelessWidget {
  final ContentItem item;
  final int index;
  final bool isSelected;
  final bool isDark;
  final bool supportsPublished;
  final bool supportsPremium;
  final bool supportsTags;
  final ContentBadgeType badgeType;
  final IconData fallbackIcon;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback onEditMetadata;
  final VoidCallback onDelete;
  final VoidCallback? onEditBlocks;

  const ContentListTile({
    super.key,
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.supportsPublished,
    required this.supportsPremium,
    required this.supportsTags,
    required this.badgeType,
    required this.fallbackIcon,
    required this.onSelectChanged,
    required this.onTap,
    required this.onEditMetadata,
    required this.onDelete,
    this.onEditBlocks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        border: Border.all(
          color: isSelected ? AppColors.primary : AdminTokens.border(isDark),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24.5),
            child: Row(
              children: [
                // Leading section
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Select ${item.title}',
                      checked: isSelected,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        onChanged: onSelectChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ContentTypeBadge(type: badgeType),
                    const SizedBox(width: 8),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AdminTokens.accentSoft(isDark),
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        border: Border.all(color: AdminTokens.border(isDark)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        child: CoverThumbnail(
                          media: item.heroMedia,
                          coverMediaType: item.coverMediaType,
                          fallback: Icon(
                            fallbackIcon,
                            color: AdminTokens.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Middle section: Title, Subtitle, Chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.title,
                            style: AdminTokens.cardTitle(
                              isDark,
                            ).copyWith(fontSize: 16),
                          ),
                          if (item.titleOlChiki != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${item.titleOlChiki})',
                              style: TextStyle(
                                fontFamily: 'OlChiki',
                                fontSize: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (supportsPublished)
                            _buildStatusChip(
                              label: item.isPublished ? 'Published' : 'Draft',
                              color: item.isPublished
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              isDark: isDark,
                            ),
                          if (supportsPremium)
                            _buildStatusChip(
                              label: item.isPremium ? 'Premium' : 'Free',
                              color: item.isPremium
                                  ? Colors.amber
                                  : Colors.blue,
                              isDark: isDark,
                            ),
                          if (supportsTags)
                            ...item.tags.map(
                              (tag) => _buildChip('#$tag', isDark),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Trailing actions section
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEditBlocks != null) ...[
                      AdminIconAction(
                        icon: Icons.dashboard_customize_rounded,
                        tooltip: 'Edit content blocks',
                        onTap: onEditBlocks!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    AdminIconAction(
                      icon: Icons.edit_rounded,
                      tooltip: 'Edit metadata',
                      onTap: onEditMetadata,
                    ),
                    const SizedBox(width: 6),
                    AdminIconAction(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
                      destructive: true,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05);
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AdminTokens.accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
