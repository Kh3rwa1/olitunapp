import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/motion/motion.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import 'widgets/hero_category_card.dart';
import 'widgets/bento_category_card.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  @override
  void initState() {
    super.initState();
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
      bottomNavigationBar: const BannerAdWidget(placement: 'lessons_bottom'),
      body: SafeArea(
        child: categories.when(
          data: (data) => BrandedRefreshIndicator(
            onRefresh: () async {
              await ref.read(categoryNotifierProvider.notifier).refresh();
              ref.invalidate(contentListProvider((ContentKind.lesson, null)));
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
                                style: AppTypography.inter(
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
                                style: AppTypography.inter(
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
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                    const SizedBox(height: 32),

                    // --- Hero Card (First Category) ---
                    if (data.isNotEmpty)
                      AnimatedBentoChild(
                        index: 0,
                        child: PressableScale(
                          onTap: () {
                            final category = data.first;
                            final id = category.id;
                            final isAlphabet =
                                id == 'cat_alphabets' ||
                                id == 'cat_letters' ||
                                id == 'letters';
                            if (isAlphabet) {
                              context.push('/letter/standalone/all');
                            } else {
                              context.go('/lessons/${category.id}');
                            }
                          },
                          child: Hero(
                            tag: MotionTokens.heroTag(
                              'category',
                              data.first.id,
                            ),
                            child: HeroCategoryCard(
                              category: data.first,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const RepaintBoundary(
                      child: NativeAdWidget(placement: 'lessons_native'),
                    ),
                    const SizedBox(height: 24),

                    // --- Bento Grid of Remaining Categories ---
                    if (data.length > 1) ...[
                      Text(
                        'MORE PATHS',
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveLayout.gridColumns(context),
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
                              onTap: () {
                                final id = category.id;
                                final isAlphabet =
                                    id == 'cat_alphabets' ||
                                    id == 'cat_letters' ||
                                    id == 'letters';
                                if (isAlphabet) {
                                  context.push('/letter/standalone/all');
                                } else {
                                  context.go('/lessons/${category.id}');
                                }
                              },
                              child: Hero(
                                tag: MotionTokens.heroTag(
                                  'category',
                                  category.id,
                                ),
                                child: BentoCategoryCard(
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
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load lessons',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
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
            const Row(
              children: [
                Skeleton(width: 44, height: 44, borderRadius: 16),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 120, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    Skeleton(width: 200, height: 24, borderRadius: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Hero card skeleton
            const Skeleton(
              width: double.infinity,
              height: 220,
              borderRadius: 32,
            ),
            const SizedBox(height: 32),
            // Subtitle skeleton
            const Skeleton(width: 100, height: 12, borderRadius: 4),
            const SizedBox(height: 16),
            // Grid skeletons
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.gridColumns(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
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

