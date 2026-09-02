import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';

// ═══════════════ BENTO CATEGORY CARD ═══════════════

class BentoCategoryCard extends StatelessWidget {
  final dynamic category;
  final int index;
  final bool isDark;

  const BentoCategoryCard({
    super.key,
    required this.category,
    required this.index,
    required this.isDark,
  });

  static const List<LinearGradient> _gradients = [
    AppColors.skyBlueGradient,
    AppColors.peachGradient,
    AppColors.mintGradient,
    AppColors.sunsetGradient,
    AppColors.purpleGradient,
    AppColors.premiumCoral,
  ];

  static const List<IconData> _icons = [
    Icons.translate_rounded,
    Icons.calculate_rounded,
    Icons.forum_rounded,
    Icons.auto_stories_rounded,
    Icons.school_rounded,
    Icons.extension_rounded,
  ];

  IconData _getIcon() {
    switch (category.iconName) {
      case 'alphabet':
        return Icons.translate_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'words':
        return Icons.forum_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return _icons[index % _icons.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];

    return BentoCell(
      padding: const EdgeInsets.all(20),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(_getIcon(), color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            category.titleLatin,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Ol Chiki subtitle
          if (category.titleOlChiki.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'OlChiki',
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Arrow indicator
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : gradient.colors.first.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: gradient.colors.first,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
