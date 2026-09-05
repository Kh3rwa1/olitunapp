import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';

class HeroCategoryCard extends StatelessWidget {
  final dynamic category;
  final bool isDark;

  const HeroCategoryCard({
    super.key,
    required this.category,
    required this.isDark,
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
        return AppColors.purpleGradient;
      default:
        return AppColors.heroGradient;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'alphabet':
        return Icons.translate_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'words':
        return Icons.forum_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(category.gradientPreset);
    final floatingIcon = Icon(
      _getIcon(category.iconName),
      size: 120,
      color: Colors.white.withValues(alpha: 0.15),
    );

    final action = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.play_arrow_rounded, color: Colors.black),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'START LEARNING',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    return BentoCell(
      gradient: gradient,
      borderRadius: 32,
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      padding: const EdgeInsets.all(28),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: ExcludeSemantics(child: floatingIcon),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.titleLatin,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              if (category.titleOlChiki.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.titleOlChiki,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'OlChiki',
                    color: Colors.black,
                  ),
                ),
              ],
              if (category.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  category.description!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              action,
            ],
          ),
        ],
      ),
    );
  }
}
