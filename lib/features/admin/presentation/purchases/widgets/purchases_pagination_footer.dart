import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

class PurchasesFreshnessHeader extends StatelessWidget {
  final DateTime lastRefreshed;
  final int recordCount;
  final bool isDark;

  const PurchasesFreshnessHeader({
    super.key,
    required this.lastRefreshed,
    required this.recordCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: AdminTokens.textMuted(isDark),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Data freshness: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastRefreshed)} UTC · Loaded: $recordCount records',
            overflow: TextOverflow.ellipsis,
            style: AdminTokens.label(
              isDark,
            ).copyWith(color: AdminTokens.textMuted(isDark), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class PurchasesCompletenessBanner extends StatelessWidget {
  final bool isSampledOrPartial;
  final int recordCount;
  final bool isDark;

  const PurchasesCompletenessBanner({
    super.key,
    required this.isSampledOrPartial,
    required this.recordCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isSampledOrPartial) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.amber,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Partial metrics — displaying loaded $recordCount records. Load next pages below to compute complete historical metrics.',
                style: AdminTokens.body(isDark).copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    if (recordCount >= 50) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Complete metrics — all $recordCount matching historical records loaded.',
                style: AdminTokens.body(isDark).copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class PurchasesPaginationFooter extends StatelessWidget {
  final AdminPurchasesState state;
  final VoidCallback onLoadNextPage;
  final bool isDark;

  const PurchasesPaginationFooter({
    super.key,
    required this.state,
    required this.onLoadNextPage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.hasMore && !state.hasLoadMoreError) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.hasLoadMoreError) ...[
            Semantics(
              liveRegion: true,
              label: 'Load more purchases failed',
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.loadMoreFailure?.userMessage ??
                            'Failed to load next page of purchases.',
                        style: AdminTokens.body(isDark).copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: state.isLoadingMore ? null : onLoadNextPage,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (state.hasMore)
            Center(
              child: OutlinedButton.icon(
                onPressed: state.isLoadingMore ? null : onLoadNextPage,
                icon: state.isLoadingMore
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  state.isLoadingMore
                      ? 'Loading More…'
                      : 'Load Next 50 Purchases',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
