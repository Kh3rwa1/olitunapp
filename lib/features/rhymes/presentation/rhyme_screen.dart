import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/rhyme_model.dart';
import 'widgets/enchanted_visualizer.dart';
import 'widgets/tilt_card.dart';

import 'widgets/whimsical_background.dart';
import '../../../core/presentation/layout/responsive_layout.dart';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                          : AppColors.primaryDark.withValues(
                                              alpha: 0.6,
                                            ),
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
                          // Decorative Icon with layered animations
                          _AnimatedMusicIcon(
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
                            color: (isDark ? Colors.white : AppColors.primary)
                                .withValues(alpha: 0.15),
                          ),
                    ],
                  ),
                ),
              ),

              // --- Animated Category Filter chips ---
              categoriesAsync.when(
                data: (categories) => SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 24,
                      ),
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () => setState(() {
                            _selectedCategory = null;
                            _selectedSubcategory = null;
                          }),
                          isDark: isDark,
                        ),
                        ...categories.map(
                          (cat) => _buildFilterChip(
                            label: cat.nameLatin,
                            isSelected: _selectedCategory == cat.nameLatin,
                            onTap: () => setState(() {
                              _selectedCategory = cat.nameLatin;
                              _selectedSubcategory = null;
                            }),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),
                ),
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // --- Cascading Subcategory chips ---
              if (_selectedCategory != null)
                subcategoriesAsync.when(
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
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 24,
                            ),
                            children: [
                              _buildFilterChip(
                                label: 'All ${_selectedCategory ?? ""}',
                                isSelected: _selectedSubcategory == null,
                                onTap: () =>
                                    setState(() => _selectedSubcategory = null),
                                isDark: isDark,
                                small: true,
                              ),
                              ...filtered.map(
                                (sub) => _buildFilterChip(
                                  label: sub.nameLatin,
                                  isSelected:
                                      _selectedSubcategory == sub.nameLatin,
                                  onTap: () => setState(
                                    () => _selectedSubcategory = sub.nameLatin,
                                  ),
                                  isDark: isDark,
                                  small: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.1),
                    );
                  },
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // --- Featured Card with Glassmorphism 2.0 ---
              rhymesAsync.when(
                data: (rhymes) {
                  final filtered = _filterRhymes(rhymes);
                  return filtered.isNotEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 24,
                            ),
                            child: _FeaturedRhymeCard(rhyme: filtered.first),
                          ),
                        )
                      : const SliverToBoxAdapter(child: SizedBox.shrink());
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              // --- Section Title ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
                  child: Row(
                    children: [
                      Text(
                        'DISCOVER MORE',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms)
                          .slideX(begin: -0.2),
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
                                    (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                    AppColors.primary.withValues(
                                      alpha: 0.3 + 0.2 * math.sin(_dividerGlowController.value * 2 * math.pi),
                                    ),
                                    (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // --- Bento Grid with Staggered Entrance ---
              rhymesAsync.when(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveLayout.gridColumns(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 3,
                        ),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isDesktop
                            ? 1.0
                            : (isTablet ? 1.0 : 0.95),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return TiltCard(
                              child: _BentoRhymeCard(
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
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Container(
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
                            color: isDark
                                ? Colors.red.shade300
                                : Colors.red.shade400,
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
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool small = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _AnimatedFilterChip(
        label: label,
        isSelected: isSelected,
        onTap: onTap,
        isDark: isDark,
        small: small,
      ),
    );
  }
}

// --- Animated Music Icon with layered glow rings ---
class _AnimatedMusicIcon extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _AnimatedMusicIcon({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = 0.8 + 0.2 * math.sin(controller.value * 2 * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 64 * pulse,
              height: 64 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1 * pulse),
                  width: 2,
                ),
              ),
            ),
            // Middle glow ring
            Container(
              width: 52 * pulse,
              height: 52 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15 * pulse),
                  width: 1.5,
                ),
              ),
            ),
            // Core icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: math.sin(controller.value * 2 * math.pi) * 0.15,
                child: Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack);
  }
}

// --- Animated Filter Chip with bounce + glow ---
class _AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool small;

  const _AnimatedFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.small = false,
  });

  @override
  State<_AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<_AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.92);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.small ? 14 : 20,
            vertical: widget.small ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(widget.isSelected ? 16 : 24),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                      spreadRadius: -4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.fredoka(
              fontSize: widget.small ? 12 : 14,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              color: widget.isSelected
                  ? Colors.white
                  : (widget.isDark ? Colors.white60 : Colors.black54),
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _FeaturedRhymeCard extends StatefulWidget {
  final RhymeModel rhyme;
  const _FeaturedRhymeCard({required this.rhyme});

  @override
  State<_FeaturedRhymeCard> createState() => _FeaturedRhymeCardState();
}

class _FeaturedRhymeCardState extends State<_FeaturedRhymeCard>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late final AnimationController _playPulseController;

  @override
  void initState() {
    super.initState();
    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _playPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;

    return GlassCard(
          blur: 24,
          borderRadius: 40,
          padding: EdgeInsets.zero,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          child: Stack(
            children: [
              // Visualizer Background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EnchantedVisualizer(
                  isPlaying: _isPlaying,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              // Reflective Gloss
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildBadge(
                          'FEATURED',
                          Colors.white.withValues(alpha: 0.2),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.3)
                            .scale(begin: const Offset(0.8, 0.8)),
                        if (widget.rhyme.subcategory != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            widget.rhyme.subcategory?.toUpperCase() ?? '',
                            Colors.white.withValues(alpha: 0.1),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideX(begin: -0.3)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ],
                        const Spacer(),
                        _PlayingIndicator(
                          isPlaying: _isPlaying,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.rhyme.titleLatin,
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideX(begin: -0.08, curve: Curves.easeOutCubic),
                    const SizedBox(height: 4),
                    Text(
                      widget.rhyme.titleOlChiki,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        fontFamily: 'OlChiki',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 500.ms)
                        .slideX(begin: -0.06, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _playPulseController.forward(from: 0);
                            setState(() => _isPlaying = !_isPlaying);
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                RotationTransition(
                              turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                              child: ScaleTransition(scale: anim, child: child),
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(_isPlaying),
                              color: color,
                            ),
                          ),
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              _isPlaying ? 'PAUSE' : 'LISTEN NOW',
                              key: ValueKey(_isPlaying),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                            shadowColor: Colors.black26,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.03, 1.03),
                          duration: 2.seconds,
                        )
                        .then()
                        .shimmer(
                          delay: 3.seconds,
                          duration: 1500.ms,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(autoPlay: false, onInit: (c) => c.forward())
        .fadeIn()
        .scale(curve: Curves.easeOutBack);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _BentoRhymeCard extends StatefulWidget {
  final RhymeModel rhyme;
  final int index;
  const _BentoRhymeCard({required this.rhyme, required this.index});

  @override
  State<_BentoRhymeCard> createState() => _BentoRhymeCardState();
}

class _BentoRhymeCardState extends State<_BentoRhymeCard>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late final AnimationController _iconBounceController;

  @override
  void initState() {
    super.initState();
    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _iconBounceController.dispose();
    super.dispose();
  }

  final List<Color> _palette = [
    AppColors.duoBlue,
    AppColors.duoGreen,
    AppColors.duoOrange,
    AppColors.duoRed,
    AppColors.duoYellow,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[widget.index % _palette.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      blur: 12,
      borderRadius: 32,
      padding: EdgeInsets.zero,
      backgroundColor: isDark
          ? color.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Visualizer Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 60,
              child: EnchantedVisualizer(
                isPlaying: _isPlaying,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForCategory(widget.rhyme.category),
                            color: color,
                            size: 16,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .rotate(
                          begin: -0.03,
                          end: 0.03,
                          duration: 3.seconds,
                          curve: Curves.easeInOutSine,
                        ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _iconBounceController.forward(from: 0);
                        setState(() => _isPlaying = !_isPlaying);
                      },
                      child: AnimatedBuilder(
                        animation: _iconBounceController,
                        builder: (context, child) {
                          final bounce = 1.0 +
                              0.2 *
                                  math.sin(_iconBounceController.value * math.pi) *
                                  (1 - _iconBounceController.value);
                          return Transform.scale(
                            scale: bounce,
                            child: child,
                          );
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: child,
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            key: ValueKey(_isPlaying),
                            color: color,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.rhyme.subcategory != null)
                  Text(
                    widget.rhyme.subcategory?.toUpperCase() ?? '',
                    style: GoogleFonts.fredoka(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: 0.15),
                const SizedBox(height: 4),
                Text(
                  widget.rhyme.titleLatin,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutCubic),
                const SizedBox(height: 2),
                Text(
                  widget.rhyme.titleOlChiki,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontFamily: 'OlChiki',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 500.ms)
                    .slideY(begin: 0.10, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'animal':
        return Icons.pets_rounded;
      case 'nature':
        return Icons.wb_sunny_rounded;
      case 'moral':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }
}

// --- Playing indicator with animated equalizer bars ---
class _PlayingIndicator extends StatefulWidget {
  final bool isPlaying;
  const _PlayingIndicator({required this.isPlaying});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _barControllers;
  final _barCount = 3;

  @override
  void initState() {
    super.initState();
    _barControllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 150),
      );
    });
    if (widget.isPlaying) _startBars();
  }

  @override
  void didUpdateWidget(_PlayingIndicator old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _startBars() : _stopBars();
    }
  }

  void _startBars() {
    for (final c in _barControllers) {
      c.repeat(reverse: true);
    }
  }

  void _stopBars() {
    for (final c in _barControllers) {
      c.animateTo(0.2, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final c in _barControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: widget.isPlaying
          ? Container(
              key: const ValueKey('equalizer'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_barCount, (i) {
                  return AnimatedBuilder(
                    animation: _barControllers[i],
                    builder: (context, child) {
                      return Container(
                        width: 3,
                        height: 6 + _barControllers[i].value * 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
            )
          : Container(
              key: const ValueKey('note'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white70,
                size: 20,
              ),
            )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
    );
  }
}
