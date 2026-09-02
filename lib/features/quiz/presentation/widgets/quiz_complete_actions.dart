import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/ads/interstitial_ad_manager.dart';
import '../../../../core/ads/rewarded_ad_manager.dart';
import '../../../../shared/widgets/sharing/share_card_payload.dart';
import '../../../../shared/widgets/sharing/social_share_modal.dart';

class QuizCompleteActions extends ConsumerWidget {
  const QuizCompleteActions({
    super.key,
    required this.isPassing,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.totalStars,
  });

  final bool isPassing;
  final int score;
  final int totalQuestions;
  final int percentage;
  final int totalStars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rewarded Bonus Stars Action
          Consumer(
            builder: (context, ref, _) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final rewarded = ref.read(rewardedAdManagerProvider);
                      final shown = await rewarded.show(
                        context: context,
                        placement: 'quiz_reward_bonus_stars',
                        rewardType: RewardType.stars,
                        amount: 50,
                        onRewardGranted: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Bonus 50 Stars Earned! ⭐'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      );
                      if (!shown && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Rewarded ad is cooling down. Try again later.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.accentGoldDark,
                      size: 22,
                    ),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Watch Ad for +50 Bonus Stars',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGoldDark,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      side: const BorderSide(
                        color: AppColors.accentGold,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (isPassing) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    SocialShareModal.show(
                      context,
                      payload: ShareCardPayload.quizResult(
                        score: score,
                        total: totalQuestions,
                        percentage: percentage,
                        stars: totalStars,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.share_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text(
                    'Share Achievement',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  ref
                      .read(interstitialAdManagerProvider)
                      .showIfAllowed(context, 'quiz_complete'),
                );
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continueButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
