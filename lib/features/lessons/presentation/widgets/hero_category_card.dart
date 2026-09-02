import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/bento_grid.dart';

// ═══════════════ HERO CATEGORY CARD ═══════════════

class HeroCategoryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = _getGradient(category.gradientPreset);
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);

    return BentoCell(
      gradient: gradient,
      borderRadius: 32,
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
      ],
      padding: const EdgeInsets.all(28),
      child: Stack(
        children: [
          // Floating icon
          Positioned(
            right: -10,
            bottom: -10,
            child:
                Icon(
                      _getIcon(category.iconName),
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.15),
                    )
                    .animate(
                      onPlay: reduceVisualEffects
                          ? null
                          : (c) => c.repeat(reverse: true),
                    )
                    .moveY(begin: 0, end: -8, duration: 2.seconds)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 2.seconds,
                    ),
          ),
          // Gloss
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
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
                    Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 10,
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
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (category.titleOlChiki.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.titleOlChiki,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'OlChiki',
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (category.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  category.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: gradient.colors.first,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'START LEARNING',
                          style: TextStyle(
                            color: gradient.colors.last,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(
                    onPlay: reduceVisualEffects
                        ? null
                        : (c) => c.repeat(reverse: true),
                  )
                  .shimmer(
                    delay: 2.seconds,
                    duration: 1500.ms,
                    color: gradient.colors.first.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
