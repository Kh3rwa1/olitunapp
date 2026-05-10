import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../categories/domain/entities/category_entity.dart';
import '../../widgets/admin_glass_card.dart';

class CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final bool isDark;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isDark,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  LinearGradient _getGradient(String preset) {
    switch (preset) {
      case 'skyBlue':
        return AppColors.skyBlueGradient;
      case 'peach':
        return AppColors.peachGradient;
      case 'mint':
        return AppColors.mintGradient;
      case 'sunset':
        return AppColors.sunsetGradient;
      case 'purple':
        return AppColors.skyBlueGradient;
      default:
        return AppColors.skyBlueGradient;
    }
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'alphabet':
        return Icons.abc_rounded;
      case 'numbers':
        return Icons.pin_rounded;
      case 'words':
        return Icons.text_fields_rounded;
      case 'arithmetic':
        return Icons.calculate_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(category.gradientPreset);
    final themeColor = gradient.colors.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdminGlassCard(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 380;
            return Row(
              children: [
                // Order Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(right: isSmall ? 8 : 16),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: isDark ? Colors.white24 : Colors.black12,
                      size: isSmall ? 20 : 24,
                    ),
                  ),
                ),

                // Icon
                Container(
                  width: isSmall ? 40 : 52,
                  height: isSmall ? 40 : 52,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIcon(category.iconName),
                    color: Colors.white,
                    size: isSmall ? 20 : 26,
                  ),
                ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),
                SizedBox(width: isSmall ? 12 : 20),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.titleLatin,
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.titleOlChiki,
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_note_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  tooltip: 'Edit Category',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                  tooltip: 'Delete Category',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
