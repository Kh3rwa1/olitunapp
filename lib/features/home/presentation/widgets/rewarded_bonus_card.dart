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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppColors.accentGold,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.dailyBonusTitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dailyBonusBody,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('home-bonus-stars'),
              onPressed: _busy ? null : _watch,
              icon: const Icon(Icons.ondemand_video_rounded),
              label: Text(l10n.watchAdBonusStars),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
