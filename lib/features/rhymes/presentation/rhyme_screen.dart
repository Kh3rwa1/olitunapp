import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/motion/branded_refresh.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../domain/rhyme_model.dart';

import 'widgets/whimsical_background.dart';
import 'widgets/tilt_card.dart';
import 'widgets/rhyme_filter_chips.dart';
import 'widgets/featured_rhyme_card.dart';
import 'widgets/bento_rhyme_card.dart';
import 'widgets/binti_guru_landing.dart';
import '../domain/rhyme_catalog.dart';
import 'widgets/rhyme_header.dart';
import 'widgets/rhyme_segmented_control.dart';
import 'widgets/bakhed_preparing_animation.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';

class RhymeScreen extends ConsumerStatefulWidget {
  const RhymeScreen({super.key});

  @override
  ConsumerState<RhymeScreen> createState() => _RhymeScreenState();
}

class _RhymeScreenState extends ConsumerState<RhymeScreen>
    with TickerProviderStateMixin {
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedTag;
  int _currentTab = 0; // 0 = Bakhed Audio, 1 = Binti Guru
  late final AnimationController _dividerGlowController;

  @override
  void initState() {
    super.initState();
    _dividerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    final reduceEffects = ref.read(reduceVisualEffectsProvider);
    if (!reduceEffects) {
      _dividerGlowController.repeat();
    }
  }

  @override
  void dispose() {
    _dividerGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reduceVisualEffectsProvider, (previous, next) {
      if (next) {
        _dividerGlowController.stop();
      } else {
        _dividerGlowController.repeat();
      }
    });

    ref.listen<AsyncValue<List<ConnectivityResult>>>(appConnectivityProvider, (
      previous,
      next,
    ) {
      final prevOffline =
          previous?.value?.contains(ConnectivityResult.none) ?? true;
      final nextOnline =
          next.value != null && !next.value!.contains(ConnectivityResult.none);
      if (prevOffline && nextOnline) {
        ref.invalidate(contentListProvider((ContentKind.rhyme, null)));
      }
    });

    final rhymesAsync = ref
        .watch(contentListProvider((ContentKind.rhyme, null)))
        .whenData((list) => list.map((item) => item.toRhymeModel()).toList());
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);
    final catRhymes = rhymesAsync.maybeWhen(
      data: (list) => list
          .where(
            (r) =>
                _selectedCategoryId == null ||
                r.categoryId == _selectedCategoryId ||
                r.category == _selectedCategoryId ||
                r.category == _selectedCategoryName,
          )
          .toList(),
      orElse: () => <RhymeModel>[],
    );
    final allTags = catRhymes.expand((r) => r.tags).toSet().toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const BannerAdWidget(placement: 'rhymes_bottom'),
      body: Stack(
        children: [
          WhimsicalBackground(
            child: SafeArea(
              child: BrandedRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    contentListProvider((ContentKind.rhyme, null)),
                  );
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- Premium Layered Header ---
                    SliverToBoxAdapter(
                      child: ResponsivePageContainer(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 32 : 24,
                          32,
                          isTablet ? 32 : 24,
                          24,
                        ),
                        child: RhymeHeader(isDark: isDark),
                      ),
                    ),

                    // --- Segmented Control ---
                    RhymeSegmentedControl(
                      isDark: isDark,
                      isTablet: isTablet,
                      currentTab: _currentTab,
                      onTabSelect: (tab) => setState(() => _currentTab = tab),
                    ),

                    if (_currentTab == 0) ...[
                      // --- Category Filter chips ---
                      _buildCategoryChips(categoriesAsync, isDark, isTablet),

                      // --- Tag chips ---
                      if (_selectedCategoryId != null)
                        _buildTagChips(allTags, isDark, isTablet),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // --- Featured Card ---
                      _buildFeaturedSection(rhymesAsync, isTablet),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                          ),
                          child: const RepaintBoundary(
                            child: NativeAdWidget(placement: 'rhymes_native'),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // --- Section Title ---
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                          ),
                          child: _buildDiscoverHeader(isDark),
                        ).animate().fadeIn(delay: 600.ms),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // --- Bento Grid ---
                      _buildBentoGrid(rhymesAsync, isDark, isTablet, isDesktop),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: ResponsivePageContainer(
                          padding: EdgeInsets.fromLTRB(
                            isTablet ? 32 : 24,
                            8,
                            isTablet ? 32 : 24,
                            120,
                          ),
                          child: const BintiGuruLanding(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: OfflineStatusBanner(),
          ),
        ],
      ),
    );
  }

  // ─── Category Chips ─────────────────────────────────────
  Widget _buildCategoryChips(
    AsyncValue<dynamic> categoriesAsync,
    bool isDark,
    bool isTablet,
  ) {
    return categoriesAsync.when(
      data: (categories) => SliverToBoxAdapter(
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedFilterChip(
                  label: 'All',
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                    _selectedTag = null;
                  }),
                  isDark: isDark,
                ),
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedFilterChip(
                    label: cat.nameLatin,
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () => setState(() {
                      _selectedCategoryId = cat.id;
                      _selectedCategoryName = cat.nameLatin;
                      _selectedTag = null;
                    }),
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),
      ),
      loading: () => SliverToBoxAdapter(
        child: SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Skeleton(width: 80, height: 44, borderRadius: 24),
            ),
          ),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  // ─── Tag Chips ──────────────────────────────────
  Widget _buildTagChips(List<String> tags, bool isDark, bool isTablet) {
    if (tags.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedFilterChip(
                  label: 'All ${_selectedCategoryName ?? ""}',
                  isSelected: _selectedTag == null,
                  onTap: () => setState(() {
                    _selectedTag = null;
                  }),
                  isDark: isDark,
                  small: true,
                ),
              ),
              ...tags.map(
                (tag) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedFilterChip(
                    label: '#$tag',
                    isSelected: _selectedTag == tag,
                    onTap: () => setState(() {
                      _selectedTag = tag;
                    }),
                    isDark: isDark,
                    small: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }

  // ─── Featured Section ───────────────────────────────────
  Widget _buildFeaturedSection(
    AsyncValue<List<RhymeModel>> rhymesAsync,
    bool isTablet,
  ) {
    return rhymesAsync.when(
      data: (rhymes) {
        final filtered = RhymeCatalog.filterRhymes(
          rhymes,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          tag: _selectedTag,
        );
        final selection = RhymeCatalog.selectFeatured(filtered);
        return selection.featured != null
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
                  child: FeaturedRhymeCard(rhyme: selection.featured!),
                ),
              )
            : const SliverToBoxAdapter(child: SizedBox.shrink());
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: const Skeleton(
            width: double.infinity,
            height: 240,
            borderRadius: 40,
          ),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  // ─── Discover Header ────────────────────────────────────
  Widget _buildDiscoverHeader(bool isDark) {
    return Row(
      children: [
        Text(
          'DISCOVER MORE',
          style: AppTypography.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _dividerGlowController,
            builder: (context, child) {
              return Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                      AppColors.primary.withValues(
                        alpha:
                            0.3 +
                            0.2 *
                                math.sin(
                                  _dividerGlowController.value * 2 * math.pi,
                                ),
                      ),
                      (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                    ],
                    stops: [
                      0,
                      (_dividerGlowController.value).clamp(0.1, 0.9),
                      1,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Bento Grid ─────────────────────────────────────────
  Widget _buildBentoGrid(
    AsyncValue<List<RhymeModel>> rhymesAsync,
    bool isDark,
    bool isTablet,
    bool isDesktop,
  ) {
    return rhymesAsync.when(
      data: (rhymes) {
        final filtered = RhymeCatalog.filterRhymes(
          rhymes,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          tag: _selectedTag,
        );
        final selection = RhymeCatalog.selectFeatured(filtered);
        final gridItems = selection.grid;

        if (gridItems.isEmpty) {
          // Honest states: "preparing" only when the catalogue itself is
          // empty; otherwise the items simply live in the featured hero.
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: filtered.isEmpty
                  ? BakhedPreparingAnimation(isDark: isDark)
                  : Center(
                      child: Text(
                        "That's everything here — new Bakhed coming soon!",
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveLayout.gridColumns(context),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.0 : (isTablet ? 1.0 : 0.95),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return TiltCard(
                    child: BentoRhymeCard(
                      rhyme: gridItems[index],
                      index: index,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (index * 120).ms, duration: 700.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    curve: Curves.easeOutBack,
                    delay: (index * 120).ms,
                  )
                  .slideY(
                    begin: 0.25,
                    delay: (index * 120).ms,
                    curve: Curves.easeOutCubic,
                  )
                  .rotate(
                    begin: index.isEven ? -0.02 : 0.02,
                    end: 0,
                    delay: (index * 120).ms,
                    duration: 500.ms,
                  );
            }, childCount: gridItems.length),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: const AppLoadingState(type: AppLoadingType.grid),
        ),
      ),
      error: (e, st) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: AppErrorState(
            message: 'Could not load the rhymes list.',
            onRetry: () =>
                ref.refresh(contentListProvider((ContentKind.rhyme, null))),
          ),
        ),
      ),
    );
  }
}
