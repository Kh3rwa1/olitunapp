import 'package:flutter/material.dart';
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

class _RhymeScreenState extends ConsumerState<RhymeScreen> {
  String? _selectedCategory;
  String? _selectedSubcategory;

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
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.5),
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
                                  .fadeIn(delay: 200.ms)
                                  .slideX(begin: -0.1),
                            ],
                          ),
                          const Spacer(),
                          // Decorative Icon
                          Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                              )
                              .rotate(begin: -0.05, end: 0.05),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock the magic of stories & songs',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
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
                            .fadeIn(delay: (index * 100).ms, duration: 600.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              curve: Curves.easeOutBack,
                            )
                            .slideY(begin: 0.2);
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 14 : 20,
            vertical: small ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
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
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: small ? 12 : 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
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

class _FeaturedRhymeCardState extends State<_FeaturedRhymeCard> {
  bool _isPlaying = false;

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
                        ),
                        if (widget.rhyme.subcategory != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            widget.rhyme.subcategory?.toUpperCase() ?? '',
                            Colors.white.withValues(alpha: 0.1),
                          ),
                        ],
                        const Spacer(),
                        Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.graphic_eq_rounded
                                    : Icons.music_note_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            )
                            .animate(target: _isPlaying ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.2, 1.2),
                            )
                            .then()
                            .shake(),
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.rhyme.titleOlChiki,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        fontFamily: 'OlChiki',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _isPlaying = !_isPlaying),
                          icon: Icon(
                            _isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: color,
                          ),
                          label: Text(_isPlaying ? 'PAUSE' : 'LISTEN NOW'),
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

class _BentoRhymeCardState extends State<_BentoRhymeCard> {
  bool _isPlaying = false;

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
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isPlaying = !_isPlaying),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: color,
                        size: 28,
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
                  ),
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
                ),
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
                ),
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
