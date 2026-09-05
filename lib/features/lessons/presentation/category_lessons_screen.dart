import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/content_item.dart';
import '../../../shared/providers/content_providers.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../../shared/utils/localized_content.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import 'providers/lesson_notifier.dart';
import 'widgets/category_lessons/category_browse_all_card.dart';
import 'widgets/category_lessons/category_empty_state.dart';
import 'widgets/category_lessons/category_hero_header.dart';
import 'widgets/category_lessons/category_lesson_card.dart';
import 'widgets/category_lessons/category_lessons_timeline.dart';

class CategoryLessonsScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryLessonsScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryLessonsScreen> createState() =>
      _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends ConsumerState<CategoryLessonsScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(categoryNotifierProvider);
    ref.invalidate(
      contentListProvider((ContentKind.lesson, widget.categoryId)),
    );
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
  }

  void _backToLearningPaths() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/lessons');
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final category = categories.when(
      data: (data) => _findCategory(data, widget.categoryId),
      loading: () => null,
      error: (err, stack) => null,
    );

    if (category == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        appBar: AppBar(leading: BackButton(onPressed: _backToLearningPaths)),
        body: categories.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categories.hasError
                              ? Icons.cloud_off_rounded
                              : Icons.search_off_rounded,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          categories.hasError
                              ? 'Could not load lessons'
                              : 'Learning path not found',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: _backToLearningPaths,
                          child: const Text('Back to learning paths'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    }

    final lessons = ref.watch(lessonsByCategoryProvider(widget.categoryId));
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final brandGradient = _getGradient(category.gradientPreset);
    final themeColor = brandGradient.colors.first;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      bottomNavigationBar: const BannerAdWidget(
        placement: 'category_lessons_bottom',
      ),
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CategoryHeroHeader(
              category: category,
              brandGradient: brandGradient,
              scriptMode: scriptMode,
              isDark: isDark,
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: RepaintBoundary(
                  child: NativeAdWidget(
                    placement: 'category_lessons_header_native',
                  ),
                ),
              ),
            ),
            lessons.when(
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: CategoryEmptyState(
                      isDark: isDark,
                      category: category,
                    ),
                  );
                }

                const alphabetCategoryIds = {
                  'cat_alphabets_1778594017948',
                  'cat_alphabets',
                  'cat_letters',
                  'letters',
                };
                const numberCategoryIds = {
                  'cat_numbers_1778594019015',
                  'cat_numbers',
                  'numbers',
                };

                final isAlphabet = alphabetCategoryIds.contains(category.id);
                final isNumber = numberCategoryIds.contains(category.id);
                final hasBrowseAll = isAlphabet || isNumber;
                final totalCount = data.length + (hasBrowseAll ? 1 : 0);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (hasBrowseAll && index == 0) {
                        final cardWidget = CategoryBrowseAllCard(
                          label: isAlphabet ? 'Ol Chiki' : 'Lekha',
                          olChikiLabel: isAlphabet ? 'ᱚᱞ ᱪᱤᱠᱤ' : 'ᱞᱮᱠᱷᱟ',
                          description: isAlphabet
                              ? 'Explore the complete grid dictionary of all letters'
                              : 'Explore the complete grid dictionary of all numbers',
                          onTap: () {
                            if (isAlphabet) {
                              context.push('/letter/standalone/all');
                            } else {
                              context.push('/number/standalone/all');
                            }
                          },
                          isDark: isDark,
                          gradient: brandGradient,
                          themeColor: themeColor,
                        );

                        return CategoryTimelineItem(
                              card: cardWidget,
                              index: index,
                              isFirst: true,
                              isLast: totalCount == 1,
                              isDark: isDark,
                              isLocked: false,
                              themeColor: themeColor,
                              gradient: brandGradient,
                              stepNodeChild: const Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 0.ms, duration: 400.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              curve: MotionTokens.emphasized,
                              duration: 450.ms,
                            );
                      }

                      final lessonIndex = hasBrowseAll ? index - 1 : index;
                      final lesson = data[lessonIndex];

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

                      final cardWidget = CategoryLessonCard(
                        lesson: lesson,
                        primaryTitle: primaryTitle,
                        secondaryTitle: secondaryTitle ?? '',
                        scriptMode: scriptMode,
                        isDark: isDark,
                        index: lessonIndex,
                        gradient: brandGradient,
                        themeColor: themeColor,
                        onTap: () {
                          context.push('/lesson/${lesson.id}');
                        },
                      );

                      final timelineItem =
                          CategoryTimelineItem(
                                card: cardWidget,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == totalCount - 1,
                                isDark: isDark,
                                isLocked: false,
                                themeColor: themeColor,
                                gradient: brandGradient,
                                stepNodeChild: Text(
                                  '${lessonIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (index * 80).ms, duration: 400.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                curve: MotionTokens.emphasized,
                                duration: 450.ms,
                              );

                      if (lessonIndex < data.length - 1) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            timelineItem,
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.only(left: 48, right: 8),
                              child: RepaintBoundary(
                                child: NativeAdWidget(
                                  placement: 'category_lessons_inline',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }

                      return timelineItem;
                    }, childCount: totalCount),
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
                        onPressed: () {
                          ref.invalidate(
                            contentListProvider((
                              ContentKind.lesson,
                              widget.categoryId,
                            )),
                          );
                          ref.invalidate(
                            contentListProvider((ContentKind.lesson, null)),
                          );
                        },
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
}
