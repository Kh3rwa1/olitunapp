import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../../shared/utils/localized_content.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// BENTO CONTENT GRID — AI Translate + Category cards
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
    [AppColors.accentPurple, AppColors.duoPurple],
    [AppColors.duoOrange, AppColors.duoOrangeDark],
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.duoRed, AppColors.duoRedDark],
    [AppColors.duoPurple, AppColors.accentPurple],
  ];

  Widget _buildAITranslateCard(BuildContext context) {
    return AnimatedBentoChild(
      index: 6,
      child: PressableScale(
        onTap: () => context.push('/translate'),
        child: BentoCell(
          gradient: const LinearGradient(
            colors: [AppColors.accentPurple, AppColors.duoPurple],
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
class _BentoCategoryCard extends ConsumerWidget {
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
      case 'sentences':
        return Icons.chat_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final primaryTitle = primaryLocalizedText(
      olChiki: category.titleOlChiki,
      latin: category.titleLatin,
      scriptMode: scriptMode,
    );
    final secondaryTitle = secondaryLocalizedText(
      olChiki: category.titleOlChiki,
      latin: category.titleLatin,
      scriptMode: scriptMode,
    );

    return Semantics(
      button: true,
      label: 'Learning path: $primaryTitle',
      value: secondaryTitle,
      hint: 'Double tap to open',
      child: ExcludeSemantics(
        child: PressableScale(
          onTap: () {
            final id = category.id;
            final isAlphabet =
                id == 'cat_alphabets' || id == 'cat_letters' || id == 'letters';
            if (isAlphabet) {
              context.push('/letter/standalone/all');
            } else {
              context.push('/lessons/${category.id}');
            }
          },
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
                  primaryTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 0,
                    fontFamily: primaryLocalizedFontFamily(scriptMode),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondaryTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondaryTitle,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
