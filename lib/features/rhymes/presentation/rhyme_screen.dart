import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/motion/branded_refresh.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/state_widgets.dart';
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
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  late final AnimationController _headerPulseController;
  late final AnimationController _dividerGlowController;

  @override
  void initState() {
    super.initState();
    _headerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _dividerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    final reduceEffects = ref.read(reduceVisualEffectsProvider);
    if (!reduceEffects) {
      _headerPulseController.repeat(reverse: true);
      _dividerGlowController.repeat();
    }
  }

  @override
  void dispose() {
    _headerPulseController.dispose();
    _dividerGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reduceVisualEffectsProvider, (previous, next) {
      if (next) {
        _headerPulseController.stop();
        _dividerGlowController.stop();
      } else {
        _headerPulseController.repeat(reverse: true);
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
        ref.invalidate(rhymesProvider);
        ref.invalidate(rhymeCategoriesProvider);
        ref.invalidate(rhymeSubcategoriesProvider);
      }
    });

    final rhymesAsync = ref.watch(rhymesProvider);
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);
    final subcategoriesAsync = ref.watch(rhymeSubcategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          WhimsicalBackground(
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
                    if (_selectedCategoryId != null)
                      _buildSubcategoryChips(
                        subcategoriesAsync,
                        isDark,
                        isTablet,
                      ),

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

  // ─── Header ─────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final eyebrow = scriptMode == 'olchiki' ? 'ᱥᱟᱱᱛᱟᱲᱤ' : 'Santali';
    final title = scriptMode == 'olchiki' ? l10n.rhymes : 'Bakhed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      eyebrow,
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
                      title,
                      style:
                          (scriptMode == 'olchiki'
                                  ? const TextStyle(fontFamily: 'OlChiki')
                                  : GoogleFonts.fredoka())
                              .copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                                height: 1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
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
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                    _selectedSubcategoryId = null;
                    _selectedSubcategoryName = null;
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
                      _selectedSubcategoryId = null;
                      _selectedSubcategoryName = null;
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
        final catId = _selectedCategoryId ?? '';
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
                      label: 'All ${_selectedCategoryName ?? ""}',
                      isSelected: _selectedSubcategoryId == null,
                      onTap: () => setState(() {
                        _selectedSubcategoryId = null;
                        _selectedSubcategoryName = null;
                      }),
                      isDark: isDark,
                      small: true,
                    ),
                  ),
                  ...filtered.map(
                    (sub) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AnimatedFilterChip(
                        label: sub.nameLatin,
                        isSelected: _selectedSubcategoryId == sub.id,
                        onTap: () => setState(() {
                          _selectedSubcategoryId = sub.id;
                          _selectedSubcategoryName = sub.nameLatin;
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
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: AppEmptyState(
                title: 'No rhymes found',
                description:
                    'New traditional Bakhed and songs are coming soon!',
                icon: Icons.music_note_rounded,
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
            onRetry: () => ref.refresh(rhymesProvider),
          ),
        ),
      ),
    );
  }

  List<RhymeModel> _filterRhymes(List<RhymeModel> rhymes) {
    var filtered = rhymes;
    if (_selectedCategoryId != null || _selectedCategoryName != null) {
      filtered = filtered
          .where(
            (r) =>
                r.categoryId == _selectedCategoryId ||
                r.category == _selectedCategoryId ||
                r.category == _selectedCategoryName,
          )
          .toList();
    }
    if (_selectedSubcategoryId != null || _selectedSubcategoryName != null) {
      filtered = filtered
          .where(
            (r) =>
                r.subcategoryId == _selectedSubcategoryId ||
                r.subcategory == _selectedSubcategoryId ||
                r.subcategory == _selectedSubcategoryName,
          )
          .toList();
    }
    return filtered;
  }
}
