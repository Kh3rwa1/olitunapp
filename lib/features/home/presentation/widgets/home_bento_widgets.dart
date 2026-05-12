import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_buttons.dart';

import '../../../../shared/widgets/bento_grid.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../../shared/models/content_models.dart';

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
      case 'sentences':
        return Icons.chat_rounded;
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
      onTap: () {
        final title = category.titleLatin.toLowerCase();
        final isAlphabet =
            category.iconName == 'alphabet' ||
            title.contains('alphabet') ||
            title.contains('letter');
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

// ═══════════════════════════════════════════════════════════
// HERO JOURNEY CARD — main "continue" CTA
// ═══════════════════════════════════════════════════════════
class HeroJourneyCard extends StatelessWidget {
  final String heroTitle;
  final int index;

  const HeroJourneyCard({
    super.key,
    required this.heroTitle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBentoChild(
      index: index,
      child: PressableScale(
        onTap: () => context.push('/categories'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.fluidShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child:
                    Icon(
                          Icons.rocket_launch_rounded,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.15),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: -10, duration: 2.seconds),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CONTINUE LEARNING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    heroTitle.contains(' ')
                        ? heroTitle.replaceFirst(' ', '\n')
                        : heroTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DuoButton(
                    text: 'RESUME JOURNEY',
                    color: Colors.white,
                    onPressed: () => context.push('/categories'),
                    width: double.infinity,
                    height: 52,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// QUIZ BANNER CARD — daily quiz prompt
// ═══════════════════════════════════════════════════════════
class QuizBannerCard extends StatelessWidget {
  final int quizCount;
  final int index;

  const QuizBannerCard({
    super.key,
    required this.quizCount,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBentoChild(
      index: index,
      child: PressableScale(
        onTap: () => context.push('/quizzes'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child:
                    Icon(
                          Icons.quiz_rounded,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.2),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: 0,
                          end: -8,
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'DAILY QUIZ',
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
                  const SizedBox(height: 12),
                  const Text(
                    'Test Your\nKnowledge!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$quizCount Quizzes Available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'START',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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
}

// ═══════════════════════════════════════════════════════════
// FEATURED BANNERS CAROUSEL
// ═══════════════════════════════════════════════════════════
class HomeFeaturedBannerCarousel extends StatefulWidget {
  final List<FeaturedBannerModel> banners;

  const HomeFeaturedBannerCarousel({super.key, required this.banners});

  @override
  State<HomeFeaturedBannerCarousel> createState() =>
      _HomeFeaturedBannerCarouselState();
}

class _HomeFeaturedBannerCarouselState
    extends State<HomeFeaturedBannerCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return AnimatedBentoChild(
                index: index,
                child: PressableScale(
                  onTap: () {
                    if (banner.targetRoute != null &&
                        banner.targetRoute!.isNotEmpty) {
                      context.push(banner.targetRoute!);
                    }
                  },
                  child: BentoCell(
                    padding: const EdgeInsets.all(24),
                    gradient: _getGradient(banner.gradientPreset),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -60,
                          right: -40,
                          child: Container(
                            width: 150,
                            height: 150,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (banner.subtitle != null &&
                                banner.subtitle!.isNotEmpty) ...[
                              Text(
                                banner.subtitle!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              banner.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (banner.imageUrl != null &&
                            banner.imageUrl!.isNotEmpty)
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Opacity(
                              opacity: 0.8,
                              child: Image.network(
                                banner.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                    const SizedBox.shrink(),
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2),
                          )
                        else if (banner.animationUrl != null &&
                            banner.animationUrl!.isNotEmpty)
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child:
                                Icon(
                                      Icons.star_rounded,
                                      size: 80,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .moveY(
                                      begin: 0,
                                      end: -5,
                                      duration: 2.seconds,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _currentIndex;
              return AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
