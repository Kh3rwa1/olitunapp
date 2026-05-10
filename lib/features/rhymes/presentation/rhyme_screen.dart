import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/motion/branded_refresh.dart';
import '../domain/rhyme_model.dart';

import 'widgets/whimsical_background.dart';
import 'widgets/tilt_card.dart';
import 'widgets/rhyme_filter_chips.dart';
import 'widgets/featured_rhyme_card.dart';
import 'widgets/bento_rhyme_card.dart';

class RhymeScreen extends ConsumerStatefulWidget {
  const RhymeScreen({super.key});

  @override
  ConsumerState<RhymeScreen> createState() => _RhymeScreenState();
}

class _RhymeScreenState extends ConsumerState<RhymeScreen>
    with TickerProviderStateMixin {
  String? _selectedCategory;
  String? _selectedSubcategory;
  late final AnimationController _headerPulseController;
  late final AnimationController _dividerGlowController;

  @override
  void initState() {
    super.initState();
    _headerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _dividerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _headerPulseController.dispose();
    _dividerGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rhymesAsync = ref.watch(rhymesProvider);
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);
    final subcategoriesAsync = ref.watch(rhymeSubcategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WhimsicalBackground(
        child: SafeArea(
          child: BrandedRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rhymesProvider);
              ref.invalidate(rhymeCategoriesProvider);
              ref.invalidate(rhymeSubcategoriesProvider);
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
                    child: _buildHeader(isDark),
                  ),
                ),

                // --- Category Filter chips ---
                _buildCategoryChips(categoriesAsync, isDark, isTablet),

                // --- Subcategory chips ---
                if (_selectedCategory != null)
                  _buildSubcategoryChips(subcategoriesAsync, isDark, isTablet),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // --- Featured Card ---
                _buildFeaturedSection(rhymesAsync, isTablet),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      'Santali',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: isDark
                            ? AppColors.primary
                            : AppColors.primaryDark.withValues(alpha: 0.6),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 600.ms)
                    .slideY(begin: 0.5)
                    .then()
                    .shimmer(
                      delay: 1.seconds,
                      duration: 1800.ms,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                Text(
                      'Rhymes',
                      style: GoogleFonts.fredoka(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        height: 1,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideX(begin: -0.15, curve: Curves.easeOutCubic)
                    .blurXY(begin: 4, end: 0, duration: 500.ms),
              ],
            ),
            const Spacer(),
            AnimatedMusicIcon(
              controller: _headerPulseController,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
              'Unlock the magic of stories & songs',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.3, curve: Curves.easeOutCubic)
            .then(delay: 500.ms)
            .shimmer(
              duration: 2.seconds,
              color: (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: 0.15,
              ),
            ),
      ],
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
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() {
                    _selectedCategory = null;
                    _selectedSubcategory = null;
                  }),
                  isDark: isDark,
                ),
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedFilterChip(
                    label: cat.nameLatin,
                    isSelected: _selectedCategory == cat.nameLatin,
                    onTap: () => setState(() {
                      _selectedCategory = cat.nameLatin;
                      _selectedSubcategory = null;
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

  // ─── Subcategory Chips ──────────────────────────────────
  Widget _buildSubcategoryChips(
    AsyncValue<dynamic> subcategoriesAsync,
    bool isDark,
    bool isTablet,
  ) {
    return subcategoriesAsync.when(
      data: (allSubcats) {
        final cats = ref.read(rhymeCategoriesProvider).value ?? [];
        final matching = cats
            .where((c) => c.nameLatin == _selectedCategory)
            .toList();
        final catId = matching.isNotEmpty ? matching.first.id : '';
        final filtered = allSubcats
            .where((s) => s.categoryId == catId)
            .toList();

        if (filtered.isEmpty) {
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
                      label: 'All ${_selectedCategory ?? ""}',
                      isSelected: _selectedSubcategory == null,
                      onTap: () => setState(() => _selectedSubcategory = null),
                      isDark: isDark,
                      small: true,
                    ),
                  ),
                  ...filtered.map(
                    (sub) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AnimatedFilterChip(
                        label: sub.nameLatin,
                        isSelected: _selectedSubcategory == sub.nameLatin,
                        onTap: () => setState(
                          () => _selectedSubcategory = sub.nameLatin,
                        ),
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
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Skeleton(width: 100, height: 32, borderRadius: 20),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  // ─── Featured Section ───────────────────────────────────
  Widget _buildFeaturedSection(
    AsyncValue<List<RhymeModel>> rhymesAsync,
    bool isTablet,
  ) {
    return rhymesAsync.when(
      data: (rhymes) {
        final filtered = _filterRhymes(rhymes);
        return filtered.isNotEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
                  child: FeaturedRhymeCard(rhyme: filtered.first),
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
          style: GoogleFonts.fredoka(
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
        final filtered = _filterRhymes(rhymes);
        final gridItems = filtered.length > 1
            ? filtered.sublist(1)
            : <RhymeModel>[];

        if (gridItems.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'More coming soon! ✨',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
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
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (e, st) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _buildErrorCard(isDark),
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 36,
            color: isDark ? Colors.red.shade300 : Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load rhymes',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  List<RhymeModel> _filterRhymes(List<RhymeModel> rhymes) {
    var filtered = rhymes;
    if (_selectedCategory != null) {
      filtered = filtered
          .where((r) => r.category == _selectedCategory)
          .toList();
    }
    if (_selectedSubcategory != null) {
      filtered = filtered
          .where((r) => r.subcategory == _selectedSubcategory)
          .toList();
    }
    return filtered;
  }
}
