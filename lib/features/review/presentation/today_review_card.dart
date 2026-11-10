// Today's Review hero card: the primary home-screen action.
//
// Hierarchy: TODAY'S REVIEW → CONTINUE LEARNING → EXPLORE. Nothing competes
// with this card — no banners, missions or ads above it.
// No fake urgency: when nothing is due it says so and offers the honest
// next step (continue lesson / learn something new).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/eyebrow.dart';
import '../data/review_store_notifier.dart';
import '../domain/memory_scheduler.dart';

class TodayReviewCard extends ConsumerWidget {
  final String? nextLessonId;

  /// One-line variant used when another hero action is on screen, so Home
  /// never stacks two full-height cards.
  final bool compact;

  const TodayReviewCard({super.key, this.nextLessonId, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final storeAsync = ref.watch(reviewStoreProvider);
    final due = ref.watch(dueReviewCountProvider);
    final retained = ref.watch(retainedItemsCountProvider);

    final isReady = storeAsync.hasValue;
    if (!isReady || due <= 0) {
      return const SizedBox.shrink();
    }

    final minutes = MemoryScheduler.estimateMinutes(due);

    void start() {
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
    }

    if (compact) {
      return _CompactReviewRow(
        title: due == 1 ? l10n.reviewDueOne : l10n.reviewDueOther(due),
        subtitle: l10n.reviewDueSubtitle(minutes),
        cta: l10n.reviewStart,
        isDark: isDark,
        onTap: start,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? AppColors.quizDarkCard : Colors.white,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Eyebrow(l10n.reviewToday, color: AppColors.emeraldDeep),
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
          const SizedBox(height: 12),
          Text(
            due == 1 ? l10n.reviewDueOne : l10n.reviewDueOther(due),
            style: TextStyle(
              fontSize: 26,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: start,
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
      ),
    );
  }
}

class _CompactReviewRow extends StatelessWidget {
  const _CompactReviewRow({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String cta;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.quizDarkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.replay_rounded,
                size: 22,
                color: isDark ? AppColors.primaryLight : AppColors.emeraldDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.webInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : AppColors.webSlate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cta,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
