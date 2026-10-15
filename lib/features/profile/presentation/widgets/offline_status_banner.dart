import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/shared/utils/test_environment.dart';
import 'package:itun/shared/widgets/state_widgets.dart';

import '../providers/user_stats_provider.dart';

/// Premium, dismissible slide-up offline recovery status banner.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connectivityAsync = ref.watch(appConnectivityProvider);
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    final isSynced = ref.watch(isStatsSyncedProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return connectivityAsync.when(
      data: (results) {
        final isOffline =
            results.contains(ConnectivityResult.none) || results.isEmpty;

        final Color backgroundColor;
        final IconData iconData;
        final String text;
        final String? buttonText;
        final VoidCallback? onButtonTap;
        final bool showProgress;

        if (isOffline) {
          backgroundColor = AppColors.accentTerracotta.withValues(alpha: 0.9);
          iconData = Icons.cloud_off_rounded;
          text = isSynced ? l10n.offlineMode : l10n.offlineProgressCached;
          buttonText = l10n.retry.toUpperCase();
          onButtonTap = () {
            HapticFeedback.lightImpact();
            ref.invalidate(appConnectivityProvider);
          };
          showProgress = false;
        } else {
          if (syncStatus == SyncStatus.syncing) {
            backgroundColor = AppColors.primary.withValues(alpha: 0.9);
            iconData = Icons.sync_rounded;
            text = l10n.syncingProgress;
            buttonText = null;
            onButtonTap = null;
            showProgress = true;
          } else if (syncStatus == SyncStatus.success) {
            backgroundColor = AppColors.accentForest.withValues(alpha: 0.9);
            iconData = Icons.cloud_done_rounded;
            text = l10n.progressSynced;
            buttonText = null;
            onButtonTap = null;
            showProgress = false;
          } else if (syncStatus == SyncStatus.error) {
            backgroundColor = AppColors.accentTerracotta.withValues(alpha: 0.9);
            iconData = Icons.sync_problem_rounded;
            text = l10n.failedToSyncProgress;
            buttonText = l10n.retry.toUpperCase();
            onButtonTap = () {
              HapticFeedback.mediumImpact();
              ref.read(userStatsProvider.notifier).syncPendingStats();
            };
            showProgress = false;
          } else {
            return const SizedBox.shrink();
          }
        }

        Widget iconWidget = Icon(iconData, color: Colors.white, size: 20);

        if (!(isFlutterTestEnvironment || reduceEffects)) {
          if (showProgress) {
            iconWidget = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          } else if (isOffline || syncStatus == SyncStatus.error) {
            iconWidget = iconWidget
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 1.seconds,
                );
          }
        }

        return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (buttonText != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onButtonTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          buttonText,
                          style: AppTypography.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
            .animate()
            .slideY(
              begin: 1.0,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn();
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
