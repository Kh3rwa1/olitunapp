import 'dart:async';

import 'package:flutter/material.dart';
import 'package:itun/shared/widgets/content_load_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'package:itun/features/profile/presentation/widgets/offline_status_banner.dart';
import '../../../core/motion/motion.dart';
import '../domain/continue_lesson_logic.dart';
import 'widgets/next_best_action_card.dart';
import '../../review/presentation/today_review_card.dart';
import 'widgets/home_content_grid.dart';
import 'providers/home_prefetch_provider.dart';
import 'widgets/home_banners_carousel.dart';
import 'widgets/learning_path_card.dart';
import 'widgets/santali_voice_promo_card.dart';
import 'widgets/ai_studio_promo_card.dart';
import '../../review/data/review_store_notifier.dart';
import 'widgets/rewarded_bonus_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_skeletons.dart';
import 'widgets/streak_lost_card.dart';
import 'widgets/word_of_day_card.dart';
import 'widgets/update_available_banner.dart';
import 'widgets/daily_goal_celebration.dart';
import 'providers/displayed_streak_provider.dart';
import 'providers/reminder_sync_provider.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';

export '../domain/continue_lesson_logic.dart';

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
      unawaited(_runFirstFrameDialogs());
    });
  }

  /// Consent first, then (never in the same frame) the notification
  /// permission — and only once the learner has actually practiced, so the
  /// prompt lands on a moment of success instead of a cold first open.
  Future<void> _runFirstFrameDialogs() async {
    try {
      await ref.read(adServiceProvider).showConsentFormIfNeeded(context);
    } catch (_) {
      // Consent must never block Home.
    }
    if (!mounted) return;
    await _requestNotificationPermissionIfEligible();
  }

  Future<void> _requestNotificationPermissionIfEligible() async {
    if (!ref.read(notificationsEnabledProvider)) return;
    final stats = ref.read(userStatsProvider).valueOrNull;
    final hasPracticed =
        ref.read(practicedTodayProvider) ||
        (stats?.completedLessons.isNotEmpty ?? false);
    try {
      await NotificationService.instance.requestPermissionIfEligible(
        hasPracticed: hasPracticed,
        prefs: ref.read(sharedPreferencesProvider),
      );
    } catch (_) {
      // Permission prompts must never break Home.
    }
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
    final isGuest = ref.watch(
      isAuthenticatedProvider.select((auth) => auth.value == false),
    );
    // One persona everywhere: the profile screen's default is 'Learner',
    // so the home greeting must not invent a second identity for guests.
    final displayUserName = userName;
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    // Keep the prefetcher subscribed for this screen's lifetime. Its state
    // (isPrefetching / timestamps) is not rendered, so don't rebuild on it;
    // refreshed data arrives through the category/content providers.
    ref.watch(homePrefetchProvider.select((_) => true));
    final dueReviews = ref.watch(dueReviewCountProvider);

    // Only the loading flag and completed-lesson ids are used here; stars/XP
    // updates must not rebuild the whole home screen.
    final statsLoading = ref.watch(
      userStatsProvider.select((stats) => stats.isLoading),
    );
    final completedIds =
        ref.watch(
          userStatsProvider.select((stats) => stats.value?.completedLessons),
        ) ??
        {};
    final lessonsAsync = ref.watch(learnerLessonsProvider);
    final allLessons = lessonsAsync.valueOrNull ?? [];
    final lastOpenedLessonId = ref.watch(lastOpenedLessonIdProvider)?.trim();
    final nextLesson = continueLessonFor(
      lessons: allLessons,
      completedLessonIds: completedIds,
      lastOpenedLessonId: lastOpenedLessonId,
      categories: categoriesAsync.valueOrNull,
    );
    final showTodayReview = dueReviews > 0;

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
    // Keeps reminder copy honest (streak / due reviews) and celebrates a
    // met daily goal once per day.
    ref.watch(reminderSyncProvider);
    listenForDailyGoalCelebration(context, ref);

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (1) Soft update nudge (hard gate for old builds lives in core/update).
        const UpdateAvailableBanner(),
        // (2) Header: greeting + Today strip (streak · goal · due reviews)
        HomeHeader(
              userName: displayUserName,
              isDark: isDark,
              isNewcomer:
                  !statsLoading &&
                  completedIds.isEmpty &&
                  (lastOpenedLessonId == null || lastOpenedLessonId.isEmpty),
            )
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.15,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 16),
        // (2b) Honest streak-loss notice, once per lost streak.
        const RepaintBoundary(child: StreakLostCard()),
        const SizedBox(height: 20),

        // (3) TODAY'S REVIEW — appears only after user left a lesson or couldn't complete
        if (showTodayReview) ...[
          RepaintBoundary(child: TodayReviewCard(nextLessonId: nextLesson?.id)),
          const SizedBox(height: 16),
        ],

        // (4) CONTINUE LEARNING — NextBestActionCard
        statsLoading
            ? HomeStatsSkeleton(isDark: isDark)
            : Column(
                children: [
                  RepaintBoundary(
                    child:
                        buildContentLoadGuard(
                          [lessonsAsync],
                          onRetry: () => ref.invalidate(
                            contentListProvider((ContentKind.lesson, null)),
                          ),
                        ) ??
                        NextBestActionCard(nextLessonId: nextLesson?.id),
                  ),
                  // Phase 7 (spec §15): proficiency-based path card, gated on
                  // the audio-quizzes flag so flag-off keeps home identical.
                  if (ref.watch(
                    featureFlagsProvider.select((f) => f.audioQuizzesEnabled),
                  )) ...[
                    const SizedBox(height: 16),
                    const RepaintBoundary(child: LearningPathCard()),
                  ],
                ],
              ),
        const SizedBox(height: 16),

        // (4b) Word of the day: a new word every day, with a path into
        // daily practice.
        const RepaintBoundary(child: WordOfDayCard()),
        const SizedBox(height: 20),

        // (5) Secondary content lives BELOW the learning actions:
        // banners carousel (explore/discover context).
        HomeBannersCarousel(isDark: isDark),

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
                Flexible(
                  child: Text(
                    l10n.homeDiscover,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.primary : AppColors.primaryDark,
                    ),
                  ),
                ),
                // The grid scrolls vertically on phones, so a "SWIPE" hint
                // there was misleading; only desktop shows an explore hint.
                if (isDesktop)
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
                      l10n.homeExploreHint,
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
              loading: () => HomeGridSkeleton(isDark: isDark),
              error: (e, st) => AppErrorState(
                message: l10n.couldNotLoadPaths,
                onRetry: _onRefresh,
              ),
            ),
            const SizedBox(height: 20),
            const RewardedBonusCard(),
            const SizedBox(height: 20),
            // One optional ad, after the learning actions and content grid.
            const RepaintBoundary(
              child: NativeAdWidget.medium(placement: 'home_native_bottom'),
            ),
            const SizedBox(height: 20),
            // Santali AI Voice studio promo — bottom of home, the viral
            // surface. Opens the Bodhan-powered TTS studio (/voice).
            const RepaintBoundary(child: SantaliVoicePromoCard()),
            const SizedBox(height: 16),
            // Santali AI Studio promo — translate / transcribe / scan tools
            // (Sarvam-powered, paid allowance with consent). Opens /studio.
            const RepaintBoundary(child: AiStudioPromoCard()),
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
}
