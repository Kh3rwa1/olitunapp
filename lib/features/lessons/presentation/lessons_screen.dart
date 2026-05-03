import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/motion/motion.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).refresh();
      ref.read(lessonNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: categories.when(
          data: (data) => BrandedRefreshIndicator(
            onRefresh: () async {
              await ref.read(categoryNotifierProvider.notifier).refresh();
              await ref.read(lessonNotifierProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsivePageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Back + Header ---
                    Row(
                      children: [
                        PressableScale(
                          onTap: () => context.go('/'),
                          haptic: HapticIntensity.selection,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.glass(context, opacity: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.glass(context, opacity: 0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEARNING PATHS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: isDark
                                      ? AppColors.primary.withValues(alpha: 0.7)
                                      : AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose Your Journey',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.1),

                    const SizedBox(height: 32),

                    // --- Hero Card (First Category) ---
                    if (data.isNotEmpty)
                      AnimatedBentoChild(
                        index: 0,
                        child: PressableScale(
                          onTap: () => context.go(
                            '/lessons/${data.first.id}',
                          ),
                          child: Hero(
                            tag: MotionTokens.heroTag(
                              'category',
                              data.first.id,
                            ),
                            child: _HeroCategoryCard(
                              category: data.first,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // --- Bento Grid of Remaining Categories ---
                    if (data.length > 1) ...[
                      Text(
                        'MORE PATHS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: -0.05),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveLayout.gridColumns(
                            context,
                            mobile: 2,
                            tablet: 3,
                            desktop: 3,
                          ),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isDesktop
                              ? 1.15
                              : (isTablet ? 1.05 : 0.92),
                        ),
                        itemCount: data.length - 1,
                        itemBuilder: (context, index) {
                          final category = data[index + 1];
                          return AnimatedBentoChild(
                            index: index + 1,
                            child: PressableScale(
                              onTap: () => context.go(
                                '/lessons/${category.id}',
                              ),
                              child: Hero(
                                tag: MotionTokens.heroTag(
                                  'category',
                                  category.id,
                                ),
                                child: _BentoCategoryCard(
                                  category: category,
                                  index: index,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
          loading: () => _buildLessonsSkeleton(context),
          error: (e, s) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 48, color: Colors.red.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Could not load lessons',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsSkeleton(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                const Skeleton(width: 44, height: 44, borderRadius: 16),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(width: 120, height: 12, borderRadius: 4),
                    const SizedBox(height: 8),
                    const Skeleton(width: 200, height: 24, borderRadius: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Hero card skeleton
            const Skeleton(width: double.infinity, height: 220, borderRadius: 32),
            const SizedBox(height: 32),
            // Subtitle skeleton
            const Skeleton(width: 100, height: 12, borderRadius: 4),
            const SizedBox(height: 16),
            // Grid skeletons
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.gridColumns(context, mobile: 2, tablet: 3, desktop: 3),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const Skeleton(borderRadius: 28),
            ),
          ],
        ),
      ),
    );
  }


}

// ═══════════════ HERO CATEGORY CARD ═══════════════

class _HeroCategoryCard extends StatelessWidget {
  final dynamic category;
  final bool isDark;

  const _HeroCategoryCard({required this.category, required this.isDark});

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

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'alphabet':
        return Icons.translate_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'words':
        return Icons.forum_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(category.gradientPreset);

    return BentoCell(
      gradient: gradient,
      borderRadius: 32,
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
      ],
      padding: const EdgeInsets.all(28),
      child: Stack(
        children: [
          // Floating icon
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
                  _getIcon(category.iconName),
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.15),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 2.seconds)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                ),
          ),
          // Gloss
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'RECOMMENDED',
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
              const SizedBox(height: 16),
              Text(
                category.titleLatin,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (category.titleOlChiki.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.titleOlChiki,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'OlChiki',
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (category.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  category.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: gradient.colors.first, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'START LEARNING',
                      style: TextStyle(
                        color: gradient.colors.last,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    delay: 2.seconds,
                    duration: 1500.ms,
                    color: gradient.colors.first.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════ BENTO CATEGORY CARD ═══════════════

class _BentoCategoryCard extends StatelessWidget {
  final dynamic category;
  final int index;
  final bool isDark;

  const _BentoCategoryCard({
    required this.category,
    required this.index,
    required this.isDark,
  });

  static const List<LinearGradient> _gradients = [
    AppColors.skyBlueGradient,
    AppColors.peachGradient,
    AppColors.mintGradient,
    AppColors.sunsetGradient,
    AppColors.purpleGradient,
    AppColors.premiumCoral,
  ];

  static const List<IconData> _icons = [
    Icons.translate_rounded,
    Icons.calculate_rounded,
    Icons.forum_rounded,
    Icons.auto_stories_rounded,
    Icons.school_rounded,
    Icons.extension_rounded,
  ];

  IconData _getIcon() {
    switch (category.iconName) {
      case 'alphabet':
        return Icons.translate_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'words':
        return Icons.forum_rounded;
      case 'stories':
        return Icons.auto_stories_rounded;
      default:
        return _icons[index % _icons.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];

    return BentoCell(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(_getIcon(), color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            category.titleLatin,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Ol Chiki subtitle
          if (category.titleOlChiki.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              category.titleOlChiki,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'OlChiki',
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Arrow indicator
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : gradient.colors.first.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: gradient.colors.first,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
