import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../../shared/utils/localized_content.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../../shared/models/catalog/category_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'home_tool_tile.dart';

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

  /// Translate + AI Voice as two quiet tool tiles (same destinations as the
  /// old gradient banners).
  Widget _buildToolsRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBentoChild(
      index: 6,
      // IntrinsicHeight: a stretched Row needs a bounded height inside the
      // scrolling Column, and both tiles should match each other's height.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: HomeToolTile(
                icon: Icons.translate_rounded,
                title: l10n.instantTranslate,
                subtitle: l10n.anyLanguageToOlChiki,
                accent: AppColors.indigoVivid,
                onTap: () => context.push('/translate'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: HomeToolTile(
                icon: Icons.mic_rounded,
                title: l10n.aiVoiceTitle,
                subtitle: l10n.aiVoicePromoSubtitle,
                onTap: () => context.push('/voice'),
              ),
            ),
          ],
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
                Expanded(flex: 2, child: _buildToolsRow(context)),
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
          _buildToolsRow(context),
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
      // A lone last tile spans the row instead of leaving an empty half.
      rows.add(
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < rowItems.length; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: rowItems[j]),
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
        return Icons.abc_rounded;
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
        borderRadius: 20,
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
                    color: gradientColors[0].withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    // Lighten in dark mode: deep accents (the purple ABC)
                    // nearly vanished on the dark card.
                    color: isDark
                        ? Color.lerp(gradientColors[0], Colors.white, 0.35)
                        : gradientColors[0],
                    size: 21,
                  ),
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
