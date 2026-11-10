import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/ad_state.dart';
import '../../../../core/ads/rewarded_ad_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Opt-in rewarded ad on Home: watch a short ad, earn 50 stars. Only shown
/// to learners who see ads (ad-free users would get free stars).
class RewardedBonusCard extends ConsumerStatefulWidget {
  const RewardedBonusCard({super.key});

  @override
  ConsumerState<RewardedBonusCard> createState() => _RewardedBonusCardState();
}

class _RewardedBonusCardState extends ConsumerState<RewardedBonusCard> {
  bool _busy = false;

  Future<void> _watch() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await ref
        .read(rewardedAdManagerProvider)
        .show(
          context: context,
          placement: 'home_bonus_stars',
          rewardType: RewardType.stars,
          amount: 50,
          onRewardGranted: () {},
        );
    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted ? l10n.bonusStarsEarned : l10n.rewardedAdCooldown,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(adStateProvider).shouldShowAds) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.webBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.stars_rounded,
            color: AppColors.accentGold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dailyBonusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.webInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.dailyBonusBody,
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
          const SizedBox(width: 8),
          TextButton(
            key: const ValueKey('home-bonus-stars'),
            onPressed: _busy ? null : _watch,
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.primaryLight
                  : AppColors.emeraldDeep,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(l10n.watchAd),
          ),
        ],
      ),
    );
  }
}
