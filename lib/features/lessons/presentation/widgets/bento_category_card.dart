import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';

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
    final largeText = MediaQuery.textScalerOf(context).scale(17) > 22;
    final foreground = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return BentoCell(
      padding: const EdgeInsets.all(20),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getIcon(), color: Colors.black, size: 26),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category.titleLatin,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: foreground,
              letterSpacing: -0.3,
            ),
            maxLines: largeText ? null : 2,
            overflow: largeText ? null : TextOverflow.ellipsis,
          ),
          if (category.titleOlChiki.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'OlChiki',
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: largeText ? null : 2,
              overflow: largeText ? null : TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(Icons.arrow_forward_rounded, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
