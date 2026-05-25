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
import '../../../shared/models/content_item.dart';
import '../../../shared/models/content_item_extensions.dart';
import '../../../shared/repositories/content_repository.dart';

import 'widgets/whimsical_background.dart';
import 'widgets/tilt_card.dart';
import 'widgets/rhyme_filter_chips.dart';
import 'widgets/featured_rhyme_card.dart';
import 'widgets/bento_rhyme_card.dart';
import 'widgets/enchanted_visualizer.dart';
import 'widgets/binti_guru_landing.dart';

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
        ref.invalidate(contentListProvider((ContentKind.rhyme, null)));
      }
    });

    final rhymesAsync = ref.watch(contentListProvider((ContentKind.rhyme, null))).whenData(
      (list) => list.map((item) => item.toRhymeModel()).toList(),
    );
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
      body: Stack(
        children: [
          WhimsicalBackground(
            child: SafeArea(
              child: BrandedRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(contentListProvider((ContentKind.rhyme, null)));
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

                    // --- Segmented Control ---
                    _buildSegmentedControl(isDark, isTablet),

                    if (_currentTab == 0) ...[
                      // --- Category Filter chips ---
                      _buildCategoryChips(categoriesAsync, isDark, isTablet),

                      // --- Tag chips ---
                      if (_selectedCategoryId != null)
                        _buildTagChips(allTags, isDark, isTablet),

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

  Widget _buildSegmentedControl(bool isDark, bool isTablet) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: 12,
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: _currentTab == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _currentTab = 0),
                      child: Center(
                        child: Text(
                          '🎵 Bakhed Audio',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _currentTab == 0
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _currentTab = 1),
                      child: Center(
                        child: Text(
                          '🧑‍🏫 Binti Guru',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _currentTab == 1
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _BakhedPreparingAnimation(isDark: isDark),
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
            onRetry: () => ref.refresh(contentListProvider((ContentKind.rhyme, null))),
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
    if (_selectedTag != null) {
      filtered = filtered.where((r) => r.tags.contains(_selectedTag)).toList();
    }
    return filtered;
  }
}

class _BakhedPreparingAnimation extends ConsumerWidget {
  const _BakhedPreparingAnimation({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.8);

    return Center(
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420, minHeight: 280),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: EnchantedVisualizer(
                        isPlaying: !reduceEffects,
                        color: AppColors.primary,
                        showParticles: !reduceEffects,
                        height: 132,
                      ),
                    ),
                    Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                            size: 42,
                          ),
                        )
                        .animate(
                          target: reduceEffects ? 0 : 1,
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1.08, 1.08),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Bakhed are being prepared',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New listening stories will appear here after publishing.',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  height: 1.35,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
