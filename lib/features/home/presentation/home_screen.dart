import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../core/motion/motion.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import 'widgets/today_affirmation_card.dart';
import 'widgets/next_best_action_card.dart';
import 'widgets/today_mission_card.dart';
import 'widgets/home_content_grid.dart';
import 'providers/home_prefetch_provider.dart';
import 'widgets/home_banners_carousel.dart';
import 'widgets/learning_path_card.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';

@visibleForTesting
LessonEntity? continueLessonFor({
  required List<LessonEntity> lessons,
  required Set<String> completedLessonIds,
  String? lastOpenedLessonId,
}) {
  final normalizedLastOpened = lastOpenedLessonId?.trim();
  if (normalizedLastOpened != null && normalizedLastOpened.isNotEmpty) {
    for (final lesson in lessons) {
      if (lesson.id == normalizedLastOpened &&
          !completedLessonIds.contains(lesson.id)) {
        return lesson;
      }
    }
  }

  for (final lesson in lessons) {
    if (!completedLessonIds.contains(lesson.id)) {
      return lesson;
    }
  }

  return null;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Prefetch core content and refresh categories using homePrefetchProvider
    // with staleness check to prevent redundant network hits.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homePrefetchProvider.notifier).prefetch();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(homePrefetchProvider.notifier).prefetch(forceRefresh: true);
    if (!mounted) return;
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
    ref.invalidate(featuredBannersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final isAuthAsync = ref.watch(isAuthenticatedProvider);
    final isGuest = isAuthAsync.value == false;
    // One persona everywhere: the profile screen's default is 'Learner',
    // so the home greeting must not invent a second identity for guests.
    final displayUserName = userName;
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    // Watch prefetch provider to trigger rebuilds or updates
    ref.watch(homePrefetchProvider);

    final statsAsync = ref.watch(userStatsProvider);
    final completedIds = statsAsync.value?.completedLessons ?? {};
    final allLessons = ref.watch(learnerLessonsProvider).value ?? [];
    final nextLesson = continueLessonFor(
      lessons: allLessons,
      completedLessonIds: completedIds,
      lastOpenedLessonId: ref.watch(lastOpenedLessonIdProvider),
    );

    // Seamless automatic background data sync when recovering connection
    ref.listen<AsyncValue<List<ConnectivityResult>>>(appConnectivityProvider, (
      previous,
      next,
    ) {
      final prevOffline =
          previous?.value?.contains(ConnectivityResult.none) ?? true;
      final nextOnline =
          next.value != null && !next.value!.contains(ConnectivityResult.none);
      if (prevOffline && nextOnline) {
        _onRefresh();
        ref.read(userStatsProvider.notifier).syncPendingStats();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final l10n = AppLocalizations.of(context)!;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (2) Header: Johar + user name only
        _buildHeader(userName: displayUserName, isDark: isDark)
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 20),

        // (2b) Featured banners carousel — hidden when empty
        HomeBannersCarousel(isDark: isDark),
        const SizedBox(height: 20),

        // (3) TodayAffirmationCard - the hero with more vertical breathing room
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: RepaintBoundary(child: TodayAffirmationCard()),
        ),
        const SizedBox(height: 16),
        const RepaintBoundary(
          child: NativeAdWidget(placement: 'home_native_wisdom'),
        ),
        const SizedBox(height: 20),

        // (4) NextBestActionCard & TodayMissionCard or Loading Skeleton
        statsAsync.isLoading
            ? _buildStatsSkeleton(isDark)
            : Column(
                children: [
                  RepaintBoundary(
                    child: NextBestActionCard(nextLessonId: nextLesson?.id),
                  ),
                  // Phase 7 (spec §15): proficiency-based path card, gated on
                  // the audio-quizzes flag so flag-off keeps home identical.
                  if (ref.watch(featureFlagsProvider).audioQuizzesEnabled) ...[
                    const SizedBox(height: 16),
                    const RepaintBoundary(child: LearningPathCard()),
                  ],
                  const SizedBox(height: 16),
                  const RepaintBoundary(
                    child: NativeAdWidget(
                      placement: 'home_native',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RepaintBoundary(child: TodayMissionCard()),
                ],
              ),
        const SizedBox(height: 24),

        // (6) Guest CTA banner (thin, only if isGuest) - 48dp banner
        if (isGuest) ...[
          Builder(
            builder: (context) {
              final card = PressableScale(
                onTap: () => context.push('/login'),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.24 : 0.16,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.guestSignInCta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white70 : AppColors.primaryDark,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
              if (reduceVisualEffects) return card;
              return card.animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
            },
          ),
        ],

        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeDiscover,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.primary : AppColors.primaryDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDesktop ? l10n.homeExploreHint : l10n.homeSwipeHint,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) {
                return HomeContentGrid(
                  isDark: isDark,
                  cols: isDesktop
                      ? 4
                      : (ResponsiveLayout.isTablet(context) ? 3 : 2),
                  categories: categories,
                );
              },
              loading: () => _buildSkeletonGrid(isDark),
              error: (e, st) => AppErrorState(
                message: l10n.couldNotLoadPaths,
                onRetry: _onRefresh,
              ),
            ),
            const SizedBox(height: 20),
            const RepaintBoundary(
              child: NativeAdWidget(placement: 'home_native_bottom'),
            ),
          ],
        ),

        SizedBox(height: isDesktop ? 32 : 120),
      ],
    );

    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.transparent
          : isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      bottomNavigationBar: const BannerAdWidget(placement: 'home_bottom'),
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: SafeArea(
          // Banner lives IN the scroll flow (first child) so it shifts
          // content down instead of covering the greeting.
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: RepaintBoundary(
              child: ResponsivePageContainer(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 0),
                  child: Column(
                    children: [const OfflineStatusBanner(), mainContent],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required String userName, required bool isDark}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.joharUser(userName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isDesktop(context)
            ? 4
            : (ResponsiveLayout.isTablet(context) ? 3 : 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(begin: 0.4, end: 0.8, duration: 800.ms);
      },
    );
  }

  Widget _buildStatsSkeleton(bool isDark) {
    return Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.4, end: 0.8, duration: 800.ms);
  }
}
