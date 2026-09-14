import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ReviewLoadErrorView extends StatelessWidget {
  final int dueTotal;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onBackHome;

  const ReviewLoadErrorView({
    super.key,
    required this.dueTotal,
    required this.isDark,
    required this.onRetry,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: isDark ? Colors.white54 : AppColors.webSlate,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.reviewLoadError,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewLoadErrorBody(dueTotal),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white60 : AppColors.webSlate,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onBackHome, child: Text(l10n.reviewBackHome)),
          ],
        ),
      ),
    );
  }
}

class ReviewCaughtUpView extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBackHome;

  const ReviewCaughtUpView({
    super.key,
    required this.isDark,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.reviewCaughtUp,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewCaughtUpShort,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white60 : AppColors.webSlate,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.reviewBackHome,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewSummaryView extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int masteredCount;
  final int starsAwarded;
  final bool isDark;
  final VoidCallback onDone;

  const ReviewSummaryView({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.masteredCount,
    required this.starsAwarded,
    required this.isDark,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = totalCount == 0
        ? 0
        : ((correctCount / totalCount) * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ᱥᱟᱨᱦᱟᱣ',
              style: TextStyle(fontFamily: 'OlChiki', fontSize: 44),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.reviewComplete,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.webInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewSummaryScore(correctCount, totalCount, accuracy) +
                  (masteredCount > 0
                      ? ' · ${l10n.reviewSummaryMastered(masteredCount, starsAwarded)}'
                      : ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white60 : AppColors.webSlate,
              ),
            ),
            if (accuracy < 100) ...[
              const SizedBox(height: 8),
              Text(
                l10n.reviewSummaryRecovery,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white54 : AppColors.webSlate,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.reviewDone,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
