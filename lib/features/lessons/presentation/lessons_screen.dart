import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../core/motion/motion.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/providers.dart';
import '../../categories/domain/entities/category_entity.dart';
import 'widgets/bento_category_card.dart';
import 'widgets/hero_category_card.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  Future<void> _refresh() async {
    await ref.read(categoryNotifierProvider.notifier).refresh();
    if (mounted) {
      ref.invalidate(contentListProvider((ContentKind.lesson, null)));
    }
  }

  void _openCategory(CategoryEntity category) {
    final id = category.id;
    if (id == 'cat_alphabets' || id == 'cat_letters' || id == 'letters') {
      context.push('/letter/standalone/all');
    } else {
      context.go('/lessons/$id');
    }
  }

  Widget _categoryCard(CategoryEntity category, int index, bool isDark) {
    return PressableScale(
      key: ValueKey('learning-path-${category.id}'),
      semanticLabel: category.titleOlChiki.isEmpty
          ? category.titleLatin
          : '${category.titleLatin}, ${category.titleOlChiki}',
      focusColor: index == 0 ? Colors.black : null,
      onTap: () => _openCategory(category),
      child: Hero(
        tag: MotionTokens.heroTag('category', category.id),
        child: index == 0
            ? HeroCategoryCard(category: category, isDark: isDark)
            : BentoCategoryCard(
                category: category,
                index: index - 1,
                isDark: isDark,
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEARNING PATHS',
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.brandTextDark
                        : AppColors.brandTextLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose Your Journey',
                  style: AppTypography.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _notice(BuildContext context, {required bool error}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              error ? Icons.wifi_off_rounded : Icons.menu_book_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              error ? 'Could not load lessons' : 'No learning paths yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error
                ? 'Check your connection and try again.'
                : 'Try refreshing, or come back soon for new lessons.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalog(BuildContext context, List<CategoryEntity> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useList =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(17) > 22;
        final padding = ResponsiveLayout.pagePadding(context);
        final remaining = data.length > 1 ? data.length - 1 : 0;
        final delegate = SliverChildBuilderDelegate(
          (context, index) {
            final card = _categoryCard(data[index + 1], index + 1, isDark);
            return useList
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  )
                : card;
          },
          childCount: remaining,
          semanticIndexOffset: 1,
        );

        return BrandedRefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            key: const PageStorageKey('learning-paths-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            semanticChildCount: data.length,
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _header(context),
                      ),
                    ),
                    if (data.isEmpty)
                      SliverToBoxAdapter(child: _notice(context, error: false)),
                    if (data.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: IndexedSemantics(
                          index: 0,
                          child: _categoryCard(data.first, 0, isDark),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: RepaintBoundary(
                            child: NativeAdWidget(placement: 'lessons_native'),
                          ),
                        ),
                      ),
                    ],
                    if (remaining > 0) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                            header: true,
                            child: Text(
                              'MORE PATHS',
                              style: AppTypography.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (useList)
                        SliverList(delegate: delegate)
                      else
                        SliverGrid(
                          delegate: delegate,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: ResponsiveLayout.gridColumns(
                                  context,
                                ),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 260,
                              ),
                        ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      bottomNavigationBar: const BannerAdWidget(placement: 'lessons_bottom'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.maxContentWidth(context),
            ),
            child: categories.when(
              data: (data) => _catalog(context, data),
              loading: () => Semantics(
                liveRegion: true,
                label: 'Loading learning paths',
                excludeSemantics: true,
                child: ListView.separated(
                  padding: ResponsiveLayout.pagePadding(context),
                  itemCount: 4,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (_, index) =>
                      const Skeleton(height: 180, borderRadius: 28),
                ),
              ),
              error: (error, stack) => SingleChildScrollView(
                padding: ResponsiveLayout.pagePadding(context),
                child: Column(
                  children: [_header(context), _notice(context, error: true)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
