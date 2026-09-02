import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/admin/presentation/widgets/content_type_badge.dart';
import 'package:itun/shared/models/content_item.dart';

class ContentGridCard extends StatelessWidget {
  final ContentItem item;
  final int index;
  final bool isSelected;
  final bool isDark;
  final bool supportsPremium;
  final ContentBadgeType badgeType;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ContentGridCard({
    super.key,
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.supportsPremium,
    required this.badgeType,
    required this.onSelectChanged,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final glyphText = item.olChiki ?? item.titleOlChiki ?? item.title;
    final isShort = glyphText.length <= 3;

    return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AdminTokens.raised(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AdminTokens.border(isDark),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: AdminTokens.raisedShadow(isDark),
            ),
            child: Stack(
              children: [
                // Checkbox for bulk actions
                Positioned(
                  top: 4,
                  left: 4,
                  child: Semantics(
                    label: 'Select ${item.title}',
                    checked: isSelected,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: onSelectChanged,
                    ),
                  ),
                ),

                // Status Dots
                Positioned(
                  top: 13,
                  right: 36,
                  child: Row(
                    children: [
                      if (supportsPremium && item.isPremium)
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.isPublished
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (item.effectiveAudioUrl == null ||
                          item.effectiveAudioUrl!.isEmpty) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Audio Missing',
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                      if (item.tracing == null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Trace Missing',
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Content Type Badge Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: ContentTypeBadge(
                    type: badgeType,
                    size: 24,
                    hasShadowRing: true,
                  ),
                ),

                // Core content: character or numeral
                Align(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        glyphText,
                        style: TextStyle(
                          fontFamily: 'OlChiki',
                          fontSize: isShort ? 32 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button at bottom
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Delete content',
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 40).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}
