import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/localized_content.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../../core/motion/motion.dart';
import '../../lessons/domain/entities/lesson_entity.dart';

import 'package:go_router/go_router.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'providers/mission_providers.dart';
// Extracted widgets
import 'widgets/home_bento_widgets.dart';
import 'widgets/today_mission_card.dart';
import 'widgets/learning_path_preview.dart';
import 'widgets/next_best_action_card.dart';

enum HomeLearnerState {
  guestNew,
  guestReturning,
  beginnerNew,
  activeLearner,
  streakRisk,
  advancedLearner,
  completedToday,
}

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
    // Providers initialize with seed data synchronously.
    // Network refresh happens automatically in the background via provider init.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prefetch core content for offline availability
      ref.read(wordsProvider);
      ref.read(numbersProvider);
      ref.read(sentencesProvider);
      ref.read(lettersProvider);
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(categoryNotifierProvider.notifier).refresh();
    await ref.read(lessonNotifierProvider.notifier).refresh();
  }

  HomeLearnerState _deriveLearnerState({
    required bool isGuest,
    required int streak,
    required int lessonsCompleted,
    required int stars,
    required LearnerLevel learnerLevel,
  }) {
    if (isGuest) {
      if (lessonsCompleted == 0) return HomeLearnerState.guestNew;
      return HomeLearnerState.guestReturning;
    }

    if (lessonsCompleted == 0) {
      return HomeLearnerState.beginnerNew;
    }

    if (streak > 0 && stars > 100) {
      return HomeLearnerState.advancedLearner;
    }

    if (streak > 3) {
      return HomeLearnerState.activeLearner;
    }

    if (streak == 1 && stars < 20) {
      return HomeLearnerState.streakRisk;
    }

    return HomeLearnerState.activeLearner;
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final stars = ref.watch(userStarsProvider);
    final lessonsCompleted = ref.watch(lessonsCompletedProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final quizzesAsync = ref.watch(quizzesProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    ref.watch(gamificationContentProvider);

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

    // Derive the next incomplete lesson for the hero card.
    final completedIds =
        ref.watch(userStatsProvider).value?.completedLessons ?? {};
    final allLessons = lessonsAsync.value ?? [];
    final nextLesson = continueLessonFor(
      lessons: allLessons,
      completedLessonIds: completedIds,
      lastOpenedLessonId: ref.watch(lastOpenedLessonIdProvider),
    );

    final isAuthAsync = ref.watch(isAuthenticatedProvider);
    final isGuest = isAuthAsync.value == false;
    final stats = statsAsync.value;
    final streak = stats?.currentStreak ?? 0;
    final learningTime = stats?.totalLearningMinutes ?? 0;
    final learnerLevel = ref.watch(learnerLevelProvider);

    // Listen to daily mission completions to record habit consistency.
    ref.listen<int>(
      Provider((ref) {
        final lesson = ref.watch(lessonCompletedTodayProvider);
        final quiz = ref.watch(quizTakenTodayProvider);
        final bakhed = ref.watch(bakhedListenedTodayProvider);
        final quick = ref.watch(quickWinCompletedTodayProvider);
        return (lesson ? 1 : 0) +
            (quiz ? 1 : 0) +
            (bakhed ? 1 : 0) +
            (quick ? 1 : 0);
      }),
      (previous, next) {
        if (next == 4) {
          ref
              .read(userStatsProvider.notifier)
              .recordDailyMissionsCompletedToday();
        }
      },
    );

    final learnerState = _deriveLearnerState(
      isGuest: isGuest,
      streak: streak,
      lessonsCompleted: lessonsCompleted,
      stars: stars,
      learnerLevel: learnerLevel,
    );

    String heroTitle = 'Start your Ol Chiki journey';
    if (learnerState == HomeLearnerState.guestNew) {
      heroTitle = 'Start your Ol Chiki journey';
    } else if (learnerState == HomeLearnerState.beginnerNew) {
      heroTitle = 'Start with your first Ol Chiki letter';
    } else if (learnerState == HomeLearnerState.streakRisk) {
      heroTitle = 'Keep your streak alive';
    } else if (nextLesson != null) {
      final lessonTitle = primaryLocalizedText(
        olChiki: nextLesson.titleOlChiki,
        latin: nextLesson.titleLatin,
        scriptMode: scriptMode,
      );
      heroTitle = 'Continue: $lessonTitle';
    }
    final quizCount = quizzesAsync.value?.length ?? 0;

    final displayUserName = isGuest ? 'Explorer' : userName;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.transparent
          : isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: Stack(
          children: [
            // High-Performance Background Mesh/Glow (GPU-rendered, 0% CPU overhead)
            if (!isDesktop && !reduceVisualEffects) ...[
              // Top-Right Primary Glow
              Positioned(
                top: -150,
                right: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom-Left Purple Glow
              Positioned(
                bottom: 100,
                left: -150,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.duoYellow.withValues(alpha: 0.15),
                        AppColors.duoYellow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: OfflineStatusBanner(),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: RepaintBoundary(
                  child: ResponsivePageContainer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(
                            context,
                            userName: displayUserName,
                            isDark: isDark,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 28),

                          // Next Best Action Card
                          const NextBestActionCard(),
                          const SizedBox(height: 24),

                          // Guest Call to Action (if not logged in)
                          if (isGuest) ...[
                            Builder(
                              builder: (context) {
                                final card = PressableScale(
                                  onTap: () => context.push('/login'),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.heroGradientAlt,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: reduceVisualEffects
                                          ? const []
                                          : AppColors.glowShadow(
                                              AppColors.primary,
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_add_alt_1_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Track Your Progress',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Create an account to save your learning journey.',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (reduceVisualEffects) return card;
                                return card
                                    .animate()
                                    .fadeIn(duration: 800.ms)
                                    .slideY(begin: 0.1);
                              },
                            ),
                          ],

                          // Featured Banners Carousel
                          if (bannersAsync.value != null &&
                              bannersAsync.value!.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final activeBanners = bannersAsync.value!
                                    .where((b) => b.isActive)
                                    .toList();
                                if (activeBanners.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: HomeFeaturedBannerCarousel(
                                    banners: activeBanners,
                                  ),
                                );
                              },
                            ),
                          ],

                          if (isTablet || isDesktop) ...[
                            // Row 1: Stats Bento Grid (tablet only)
                            if (!isDesktop) ...[
                              _buildStatsBentoGrid(
                                streak: streak,
                                stars: stars,
                                lessonsCompleted: lessonsCompleted,
                                learningTime: learningTime,
                                isDark: isDark,
                                isTablet: isTablet,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Row 2: Hero Journey + Quiz Banner
                            _buildHeroBentoRow(
                              context,
                              isDark,
                              heroTitle,
                              nextLesson?.id,
                              quizCount,
                            ),
                            const SizedBox(height: 20),

                            // Row 3: Discover / Categories
                            _buildContentBentoGrid(
                              context: context,
                              categoriesAsync: categoriesAsync,
                              isDark: isDark,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ] else ...[
                            // MOBILE VIEW: Premium, guided pedagogical hierarchy
                            // 1. Today's Mission / Quick Win
                            const TodayMissionCard(),
                            const SizedBox(height: 20),

                            // 3. Learning Path Preview
                            if (allLessons.isNotEmpty) ...[
                              LearningPathPreview(
                                lessons: allLessons,
                                completedLessonIds: completedIds,
                                currentLessonId: nextLesson?.id,
                                scriptMode: scriptMode,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // 4. Quiz / Bakhed prompt
                            QuizBannerCard(quizCount: quizCount, index: 1),
                            const SizedBox(height: 20),

                            // 5. Stats Grid (Day Streak, Stars, etc.)
                            _buildStatsBentoGrid(
                              streak: streak,
                              stars: stars,
                              lessonsCompleted: lessonsCompleted,
                              learningTime: learningTime,
                              isDark: isDark,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 20),

                            // 6. Discover / Categories
                            _buildContentBentoGrid(
                              context: context,
                              categoriesAsync: categoriesAsync,
                              isDark: isDark,
                              isTablet: isTablet,
                              isDesktop: isDesktop,
                            ),
                          ],

                          SizedBox(height: isDesktop ? 32 : 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context, {
    required String userName,
    required bool isDark,
    required bool isDesktop,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Johar, $userName!',
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
        if (!isDesktop)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications are coming soon.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              size: 52,
              backgroundColor: AppColors.glass(context, opacity: 0.05),
            ),
          ),
      ],
    );
  }

  // ─── BENTO: Stats Grid ─────────────────────────────────
  Widget _buildStatsBentoGrid({
    required int streak,
    required int stars,
    required int lessonsCompleted,
    required int learningTime,
    required bool isDark,
    required bool isTablet,
  }) {
    if (isTablet) {
      return Row(
        children: [
          Expanded(
            child: HomeBentoStatCard(
              icon: Icons.local_fire_department_rounded,
              value: streak,
              label: 'Day Streak',
              color: AppColors.duoOrange,
              index: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeBentoStatCard(
              icon: Icons.star_rounded,
              value: stars,
              label: 'Stars',
              color: AppColors.duoYellow,
              index: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeBentoStatCard(
              icon: Icons.emoji_events_rounded,
              value: lessonsCompleted,
              label: 'Milestones',
              color: AppColors.primary,
              index: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeBentoStatCard(
              icon: Icons.timer_rounded,
              value: learningTime,
              suffix: 'm',
              label: 'Time',
              color: AppColors.duoBlue,
              index: 3,
            ),
          ),
        ],
      );
    }

    // Mobile: 2x2 bento grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: HomeBentoStatCard(
                icon: Icons.local_fire_department_rounded,
                value: streak,
                label: 'Day Streak',
                color: AppColors.duoOrange,
                index: 0,
                isHero: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: HomeBentoStatCard(
                icon: Icons.star_rounded,
                value: stars,
                label: 'Stars',
                color: AppColors.duoYellow,
                index: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: HomeBentoStatCard(
                icon: Icons.emoji_events_rounded,
                value: lessonsCompleted,
                label: 'Milestones',
                color: AppColors.primary,
                index: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: HomeBentoStatCard(
                icon: Icons.timer_rounded,
                value: learningTime,
                suffix: 'm',
                label: 'Learning Time',
                color: AppColors.duoBlue,
                index: 3,
                isHero: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── BENTO: Hero + Quiz side-by-side (tablet/desktop) ──
  Widget _buildHeroBentoRow(
    BuildContext context,
    bool isDark,
    String heroTitle,
    String? nextLessonId,
    int quizCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: HeroJourneyCard(
            heroTitle: heroTitle,
            lessonId: nextLessonId,
            index: 4,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: QuizBannerCard(quizCount: quizCount, index: 5),
        ),
      ],
    );
  }

  // ─── BENTO: Content Grid (AI Tools + Categories) ───────
  Widget _buildContentBentoGrid({
    required BuildContext context,
    required AsyncValue<List<CategoryEntity>> categoriesAsync,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final cols = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DISCOVER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cols == 2 ? 'SWIPE' : 'EXPLORE',
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
              cols: cols,
              categories: categories,
            );
          },
          loading: () => _buildContentSkeleton(cols),
          error: (e, st) => AppErrorState(
            message: 'Could not load learning paths',
            onRetry: _onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSkeleton(int cols) {
    const gap = 14.0;
    return Column(
      children: [
        const Skeleton(width: double.infinity, height: 80, borderRadius: 24),
        const SizedBox(height: gap),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: 140,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const Skeleton(borderRadius: 24),
        ),
      ],
    );
  }
}
