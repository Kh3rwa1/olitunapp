// Thin "a new version is ready" strip. Soft nudge only: the hard gate for
// builds below the minimum lives in core/update. Dismissed once per latest
// build (`update_banner_dismissed_build_<latest>`).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_update_config.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

String updateBannerDismissedKey(int latestBuild) =>
    'update_banner_dismissed_build_$latestBuild';

/// Opens the Play listing. Overridable for tests.
final updateLauncherProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (kIsWeb) {
      await launchUrl(
        AppUpdatePolicy.playWebUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    final ok = await launchUrl(
      AppUpdatePolicy.playMarketUri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      await launchUrl(
        AppUpdatePolicy.playWebUri,
        mode: LaunchMode.externalApplication,
      );
    }
  };
});

/// Whether the banner should show right now (available and not dismissed).
final updateBannerVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(updateAvailableProvider)) return false;
  final latest = ref.watch(latestBuildProvider);
  if (latest == null) return false;
  final prefs = ref.watch(sharedPreferencesProvider);
  return !(prefs.getBool(updateBannerDismissedKey(latest)) ?? false);
});

class UpdateAvailableBanner extends ConsumerWidget {
  const UpdateAvailableBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateBannerVisibleProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> dismiss() async {
      final latest = ref.read(latestBuildProvider);
      if (latest == null) return;
      await ref
          .read(sharedPreferencesProvider)
          .setBool(updateBannerDismissedKey(latest), true);
      ref.invalidate(updateBannerVisibleProvider);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_alt_rounded,
            size: 18,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.updateAvailableBanner,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(updateLauncherProvider)(),
            child: Text(
              l10n.updateAvailableAction,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: l10n.streakLostDismiss,
            visualDensity: VisualDensity.compact,
            onPressed: dismiss,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? Colors.white60 : AppColors.webSlate,
            ),
          ),
        ],
      ),
    );
  }
}
