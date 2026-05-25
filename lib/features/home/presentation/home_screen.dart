import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../core/motion/motion.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import 'widgets/today_affirmation_card.dart';
import 'widgets/next_best_action_card.dart';
import 'widgets/today_mission_card.dart';
import 'widgets/home_content_grid.dart';

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
    // Prefetch core content and refresh categories from Appwrite on every
    // home-screen mount so newly added categories are always visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learnerWordsProvider);
      ref.read(learnerNumbersProvider);
      ref.read(learnerSentencesProvider);
      ref.read(learnerLettersProvider);
      // Silently refresh categories in the background — this replaces any
      // stale cache or static seed data with the live Appwrite list.
      ref.read(categoryNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(categoryNotifierProvider.notifier).refresh();
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final isAuthAsync = ref.watch(isAuthenticatedProvider);
    final isGuest = isAuthAsync.value == false;
    final displayUserName = isGuest ? 'Explorer' : userName;
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final completedIds =
        ref.watch(userStatsProvider).value?.completedLessons ?? {};
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

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (2) Header: Johar + user name only
        _buildHeader(userName: displayUserName, isDark: isDark),
        const SizedBox(height: 24),

        // (3) TodayAffirmationCard - the hero with more vertical breathing room
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: RepaintBoundary(child: TodayAffirmationCard()),
        ),
        const SizedBox(height: 24),

        // (4) NextBestActionCard - single "continue learning" CTA
        RepaintBoundary(
          child: NextBestActionCard(nextLessonId: nextLesson?.id),
        ),
        const SizedBox(height: 24),

        // (5) TodayMissionCard - daily missions strip
        const RepaintBoundary(child: TodayMissionCard()),
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
                          'Sign in to save your progress →',
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
                  'DISCOVER',
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
                    isDesktop ? 'EXPLORE' : 'SWIPE',
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
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => AppErrorState(
                message: 'Could not load learning paths',
                onRetry: _onRefresh,
              ),
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
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: Stack(
          children: [
            // (1) OfflineStatusBanner - keep as positioned overlay
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
                      child: mainContent,
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

  Widget _buildHeader({required String userName, required bool isDark}) {
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
      ],
    );
  }
}
