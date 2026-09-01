import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../providers/local_settings_provider.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import 'glass_card.dart';

bool get _isTesting {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

enum AppLoadingType { list, grid, card, page }

/// Standard premium skeleton and full-page loading indicators.
class AppLoadingState extends ConsumerWidget {
  final AppLoadingType type;
  final int count;
  final String? message;

  const AppLoadingState({
    super.key,
    this.type = AppLoadingType.list,
    this.count = 4,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    switch (type) {
      case AppLoadingType.list:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (context, index) => const SkeletonListTile(),
        );
      case AppLoadingType.grid:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: count,
          itemBuilder: (context, index) => const SkeletonGridItem(),
        );
      case AppLoadingType.card:
        return const SkeletonCard();
      case AppLoadingType.page:
        final loaderWidget = SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            backgroundColor: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        );

        return Center(
          child: GlassCard(
            blur: 20,
            borderRadius: 32,
            width: 220,
            height: 220,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isTesting || reduceEffects)
                  loaderWidget
                else
                  loaderWidget
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 2.seconds),
                const SizedBox(height: 24),
                Text(
                  message ?? 'Johar... Loading',
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
}

/// A premium, customizable empty state display card with animated icons.
class AppEmptyState extends ConsumerWidget {
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final IconData icon;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    final iconWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppColors.primary),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          borderRadius: 32,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTesting || reduceEffects)
                iconWidget
              else
                iconWidget
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 2.seconds,
                      curve: Curves.easeInOutBack,
                    ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.3,
                ),
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onButtonPressed!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText!.toUpperCase(),
                    style: AppTypography.inter(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegant error state indicator with shake animation and retry trigger.
class AppErrorState extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    final errorIconWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentTerracotta.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppColors.accentTerracotta),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          blur: 20,
          borderRadius: 32,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTesting || reduceEffects)
                errorIconWidget
              else
                errorIconWidget
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shake(hz: 1.5, duration: 2.seconds),
              const SizedBox(height: 20),
              Text(
                'Etom Badiyena! (Something went wrong)',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRetry();
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'RETRY',
                  style: AppTypography.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Global stream provider for tracking live connectivity changes.
final appConnectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final net = ref.watch(networkInfoProvider);
  return net.onConnectivityChanged;
});

/// Premium, dismissible slide-up offline recovery status banner.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          text = isSynced
              ? 'Offline mode. Showing cached content.'
              : 'Offline. Progress cached locally.';
          buttonText = 'RETRY';
          onButtonTap = () {
            HapticFeedback.lightImpact();
            ref.invalidate(appConnectivityProvider);
          };
          showProgress = false;
        } else {
          if (syncStatus == SyncStatus.syncing) {
            backgroundColor = AppColors.primary.withValues(alpha: 0.9);
            iconData = Icons.sync_rounded;
            text = 'Syncing progress...';
            buttonText = null;
            onButtonTap = null;
            showProgress = true;
          } else if (syncStatus == SyncStatus.success) {
            backgroundColor = AppColors.accentForest.withValues(alpha: 0.9);
            iconData = Icons.cloud_done_rounded;
            text = 'Progress synced!';
            buttonText = null;
            onButtonTap = null;
            showProgress = false;
          } else if (syncStatus == SyncStatus.error) {
            backgroundColor = AppColors.accentTerracotta.withValues(alpha: 0.9);
            iconData = Icons.sync_problem_rounded;
            text = 'Failed to sync progress.';
            buttonText = 'RETRY';
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

        if (!(_isTesting || reduceEffects)) {
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
