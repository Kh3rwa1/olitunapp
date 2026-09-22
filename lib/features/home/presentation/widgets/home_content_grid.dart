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
    [AppColors.accentPurple, AppColors.accentPurple],
    [AppColors.accentOchre, AppColors.accentOchreDark],
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.accentTerracotta, AppColors.accentTerracottaDark],
    [AppColors.accentPurple, AppColors.accentPurple],
  ];

  Widget _buildAITranslateCard(BuildContext context) {
    return AnimatedBentoChild(
      index: 6,
      child: PressableScale(
        onTap: () => context.push('/translate'),
        child: BentoCell(
          gradient: const LinearGradient(
            colors: [AppColors.accentPurpleDark, AppColors.indigoVivid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.violetGlow,
              blurRadius: 28,
              offset: Offset(0, 14),
              spreadRadius: -12,
            ),
          ],
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -18,
                child: IgnorePointer(
                  child: Text(
                    'ᱚ',
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 92,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Any Language → Ol Chiki',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: AppColors.indigoVivid,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
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

    // Keep label, focus and activation on the same accessible control.
    // Excluding the PressableScale subtree also excluded its tap action.
    return PressableScale(
      key: ValueKey('home_category_${category.id}'),
      semanticLabel: [primaryTitle, ?secondaryTitle].join(', '),
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
        padding: const EdgeInsets.all(18),
        borderRadius: 24,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.webBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.webInk.withValues(alpha: 0.05),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -12,
                ),
              ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withValues(alpha: 0.16),
                        gradientColors[0].withValues(alpha: 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: gradientColors[0].withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(_getIcon(), color: gradientColors[0], size: 21),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : AppColors.webSlateFaint,
                ),
              ],
            ),
            const Spacer(),
            Text(
              primaryTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : AppColors.webInk,
                fontFamily: primaryLocalizedFontFamily(scriptMode),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (secondaryTitle != null) ...[
              const SizedBox(height: 3),
              Text(
                secondaryTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'OlChiki',
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.webSlateLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
