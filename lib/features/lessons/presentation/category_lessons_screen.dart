import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import 'providers/lesson_notifier.dart';
import '../../../shared/providers/purchases_provider.dart';
import '../../../shared/widgets/paywall_bottom_sheet.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../../shared/utils/localized_content.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import 'widgets/full_bleed_hero_media.dart';
import '../../../shared/utils/media_type_resolver.dart';

class CategoryLessonsScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryLessonsScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryLessonsScreen> createState() =>
      _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends ConsumerState<CategoryLessonsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _onRefresh() async {
    await ref.read(lessonNotifierProvider.notifier).refresh();
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
    final categories = ref.watch(categoryNotifierProvider);
    final lessons = ref.watch(lessonsByCategoryProvider(widget.categoryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchasedCategories =
        ref.watch(purchasedCategoriesProvider).value ?? {};
    final scriptMode = ref.watch(effectiveScriptModeProvider);

    final category = categories.when(
      data: (data) => _findCategory(data, widget.categoryId),
      loading: () => null,
      error: (err, stack) => null,
    );

    if (category == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hasHeroMedia =
        category.courseHeroImageUrl != null &&
        category.courseHeroImageUrl!.trim().isNotEmpty;
    final heroMediaUrl = hasHeroMedia
        ? category.courseHeroImageUrl!.trim()
        : null;
    final isLottie =
        heroMediaUrl != null &&
        MediaTypeResolver.resolve(heroMediaUrl) == MediaKind.lottie;
    final brandGradient = _getGradient(category.gradientPreset);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            ParallaxHeroSliverAppBar(
              gradient: brandGradient,
              heroTag: MotionTokens.heroTag('category', category.id),
              glyph: !hasHeroMedia && category.titleOlChiki.isNotEmpty
                  ? category.titleOlChiki.characters.first
                  : null,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              title: Text(
                category.titleLatin,
                style: TextStyle(
                  fontFamily: primaryLocalizedFontFamily(scriptMode),
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              heroChildFullBleed: hasHeroMedia,
              heroChild: hasHeroMedia
                  ? FullBleedHeroMedia(
                      animationUrl: isLottie ? heroMediaUrl : null,
                      imageUrl: heroMediaUrl,
                      fallback: Text(
                        category.titleOlChiki.isNotEmpty
                            ? category.titleOlChiki.characters.first
                            : 'ᱚ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 160,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    )
                  : null,
            ),
            lessons.when(
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark, category),
                  );
                }

                final isPremium = category.unlockMode != 'free';
                final isUnlocked = purchasedCategories.contains(category.id);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final lesson = data[index];
                      final isLocked =
                          isPremium &&
                          !isUnlocked &&
                          index >= category.previewLessonCount;

                      final primaryTitle = primaryLocalizedText(
                        olChiki: lesson.titleOlChiki,
                        latin: lesson.titleLatin,
                        scriptMode: scriptMode,
                      );
                      final secondaryTitle = secondaryLocalizedText(
                        olChiki: lesson.titleOlChiki,
                        latin: lesson.titleLatin,
                        scriptMode: scriptMode,
                      );

                      return _LessonCard(
                        lesson: lesson,
                        primaryTitle: primaryTitle,
                        secondaryTitle: secondaryTitle ?? '',
                        scriptMode: scriptMode,
                        isDark: isDark,
                        index: index,
                        isLocked: isLocked,
                        showPreviewBadge:
                            isPremium &&
                            !isUnlocked &&
                            index < category.previewLessonCount,
                        onTap: isLocked
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      PaywallBottomSheet(category: category),
                                );
                              }
                            : () => context.push('/lesson/${lesson.id}'),
                      );
                    }, childCount: data.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load lessons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and try again',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(lessonNotifierProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CategoryEntity? _findCategory(List<CategoryEntity> categories, String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  Widget _buildEmptyState(bool isDark, [dynamic category]) {
    final id = category?.id ?? '';
    final isAlphabet =
        id == 'cat_alphabets' || id == 'cat_letters' || id == 'letters';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isAlphabet ? Icons.translate_rounded : Icons.school_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isAlphabet ? 'Alphabet Dictionary' : 'No lessons yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAlphabet
                ? 'Browse all available Ol Chiki letters'
                : 'Check back soon for new content',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          if (isAlphabet) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/letter/standalone/all');
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Open Dictionary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final dynamic lesson;
  final String primaryTitle;
  final String secondaryTitle;
  final String scriptMode;
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  final bool isLocked;
  final bool showPreviewBadge;

  const _LessonCard({
    required this.lesson,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.scriptMode,
    required this.isDark,
    required this.index,
    required this.onTap,
    this.isLocked = false,
    this.showPreviewBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PressableScale(
            onTap: onTap,
            child: Hero(
              tag: MotionTokens.heroTag('lesson', lesson.id),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: isLocked ? 0.03 : 0.06)
                      : (isLocked ? Colors.grey.shade100 : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(
                            alpha: isLocked ? 0.02 : 0.05,
                          ),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: primaryLocalizedFontFamily(
                                scriptMode,
                              ),
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (secondaryTitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                secondaryTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'OlChiki',
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          if (lesson.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                lesson.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildLevelBadge(lesson.level),
                              if (showPreviewBadge)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'FREE PREVIEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_done_rounded,
                                    size: 14,
                                    color: isLocked
                                        ? Colors.grey
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available Offline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isLocked
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isLocked ? Icons.lock_rounded : Icons.play_circle_rounded,
                      color: isLocked ? Colors.grey : AppColors.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideX(begin: 0.1);
  }

  Widget _buildLevelBadge(String level) {
    Color badgeColor;
    String label;

    switch (level.toLowerCase()) {
      case 'advanced':
        badgeColor = AppColors.duoRed;
        label = 'Advanced';
        break;
      case 'intermediate':
        badgeColor = AppColors.duoOrange;
        label = 'Intermediate';
        break;
      case 'beginner':
      default:
        badgeColor = AppColors.duoGreen;
        label = 'Beginner';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: badgeColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
