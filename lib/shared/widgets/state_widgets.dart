import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_info.dart';
import '../../core/theme/app_colors.dart';
import 'shimmer_loading.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/local_settings_provider.dart';
import '../utils/test_environment.dart';
import 'glass_card.dart';

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
                if (isFlutterTestEnvironment || reduceEffects)
                  loaderWidget
                else
                  loaderWidget
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 2.seconds),
                const SizedBox(height: 24),
                Text(
                  message ?? AppLocalizations.of(context)!.joharLoading,
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
              if (isFlutterTestEnvironment || reduceEffects)
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
              if (isFlutterTestEnvironment || reduceEffects)
                errorIconWidget
              else
                errorIconWidget
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shake(hz: 1.5, duration: 2.seconds),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.somethingWentWrong,
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
                  AppLocalizations.of(context)!.retry.toUpperCase(),
                  style: AppTypography.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
