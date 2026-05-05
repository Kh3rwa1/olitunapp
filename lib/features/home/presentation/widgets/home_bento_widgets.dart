import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';

import '../../../../shared/widgets/bento_grid.dart';
import '../../../categories/domain/entities/category_entity.dart';

// ═══════════════════════════════════════════════════════════
// BENTO STAT CARD — glassmorphism stat tile with hover
// ═══════════════════════════════════════════════════════════
class HomeBentoStatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String suffix;
  final String label;
  final Color color;
  final int index;
  final bool isHero;

  const HomeBentoStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.index,
    this.suffix = '',
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBentoChild(
      index: index,
      child: BentoCell(
        padding: EdgeInsets.all(isHero ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isHero ? 22 : 18),
                ),
                if (isHero) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: color,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCounter(
              value: value,
              suffix: suffix,
              style: TextStyle(
                fontSize: isHero ? 28 : 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BENTO CONTENT GRID — AI Translate + Category cards
// Uses explicit Row+Expanded for perfect alignment
// ═══════════════════════════════════════════════════════════
class HomeContentGrid extends StatelessWidget {
  final bool isDark;
  final int cols;
  final List<CategoryEntity> categories;

  const HomeContentGrid({
    super.key,
    required this.isDark,
    required this.cols,
    required this.categories,
  });

  static const _categoryGradients = [
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ];

  Widget _buildAITranslateCard(BuildContext context) {
    return AnimatedBentoChild(
      index: 6,
      child: PressableScale(
        onTap: () => context.push('/translate'),
        child: BentoCell(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Instant Translate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Any Language → Ol Chiki',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryEntity cat, int catIndex) {
    final grad = _categoryGradients[catIndex % _categoryGradients.length];
    return AnimatedBentoChild(
      index: 7 + catIndex,
      child: _BentoCategoryCard(category: cat, gradientColors: grad),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

    final catCards = List.generate(
      categories.length,
      (i) => _buildCategoryCard(categories[i], i),
    );

    if (cols >= 3) {
      final firstRowCats = catCards.take(cols - 2).toList();
      final remainingCats = catCards.skip(cols - 2).toList();

      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildAITranslateCard(context)),
                ...firstRowCats.map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: gap),
                      child: card,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (remainingCats.isNotEmpty) ...[
            const SizedBox(height: gap),
            _buildCategoryRows(remainingCats, cols, gap),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          _buildAITranslateCard(context),
          const SizedBox(height: gap),
          _buildCategoryRows(catCards, 2, gap),
        ],
      );
    }
  }

  Widget _buildCategoryRows(List<Widget> cards, int cols, double gap) {
    final rows = <Widget>[];

    for (var i = 0; i < cards.length; i += cols) {
      final rowItems = cards.skip(i).take(cols).toList();
      rows.add(
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(
                  child: j < rowItems.length
                      ? rowItems[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + cols < cards.length) {
        rows.add(SizedBox(height: gap));
      }
    }

    return Column(children: rows);
  }
}

// ═══════════════════════════════════════════════════════════
// BENTO CATEGORY CARD — individual learning path tile
// ═══════════════════════════════════════════════════════════
class _BentoCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final List<Color> gradientColors;

  const _BentoCategoryCard({
    required this.category,
    required this.gradientColors,
  });

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
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () => context.push('/lessons/${category.id}'),
      child: BentoCell(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withValues(alpha: 0.15),
                    gradientColors[1].withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(), color: gradientColors[0], size: 22),
            ),
            const Spacer(),
            Text(
              category.titleLatin,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'OlChiki',
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
