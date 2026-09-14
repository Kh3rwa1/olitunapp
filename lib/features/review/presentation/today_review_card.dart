// Today's Review hero card: the primary home-screen action.
//
// Hierarchy: TODAY'S REVIEW → CONTINUE LEARNING → EXPLORE. Nothing competes
// with this card — no banners, affirmations, missions or ads above it.
// No fake urgency: when nothing is due it says so and offers the honest
// next step (continue lesson / learn something new).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/providers.dart';
import '../../quiz/presentation/providers/mistake_provider.dart';
import '../data/review_store.dart';
import '../domain/memory_scheduler.dart';

class TodayReviewCard extends ConsumerWidget {
  final String? nextLessonId;

  const TodayReviewCard({super.key, this.nextLessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final storeAsync = ref.watch(reviewStoreProvider);
    final due = ref.watch(dueReviewCountProvider);
    final retained = ref.watch(retainedItemsCountProvider);

    final lastOpenedId = ref.watch(lastOpenedLessonIdProvider)?.trim();
    final stats = ref.watch(userStatsProvider).valueOrNull;
    final completedIds = stats?.completedLessons ?? const <String>{};
    final hasIncompleteLesson =
        lastOpenedId != null &&
        lastOpenedId.isNotEmpty &&
        !completedIds.contains(lastOpenedId);
    final mistakes = ref.watch(mistakeProvider);
    final hasMistakes = mistakes.isNotEmpty;

    final minutes = MemoryScheduler.estimateMinutes(due);
    final hasDue = due > 0;
    final isReady = storeAsync.hasValue;

    // Today's review should only appear after user left a lesson or couldn't complete
    if (!hasDue || (!hasIncompleteLesson && !hasMistakes)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? AppColors.quizDarkCard : Colors.white,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.reviewToday,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (retained > 0)
                Text(
                  l10n.reviewRetained(retained),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : AppColors.webSlate,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isReady)
            Text(
              l10n.reviewLoading,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            )
          else ...[
            Text(
              due == 1 ? l10n.reviewDueOne : l10n.reviewDueOther(due),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.reviewDueSubtitle(minutes),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : AppColors.webSlate,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Funnel denominator for "returned because they had due
                  // reviews" (numerator: review_started). Never blocks nav.
                  // ignore: discarded_futures
                  ref
                      .read(learningAnalyticsServiceProvider)
                      .track(
                        LearningAnalyticsEvents.todayReviewTapped,
                        source: 'today_review_card',
                        metadata: {'dueCount': due, 'minutes': minutes},
                      );
                  context.push('/review');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.reviewStart,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
