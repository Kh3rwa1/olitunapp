import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/ads/ad_service.dart';
import '../../../../../core/ads/ad_state.dart';
import '../../../../../core/config/ad_config.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_form_widgets.dart';
import '../controllers/admin_settings_controller.dart';

class AdminAdmobSection extends ConsumerStatefulWidget {
  const AdminAdmobSection({super.key});

  @override
  ConsumerState<AdminAdmobSection> createState() => _AdminAdmobSectionState();
}

class _AdminAdmobSectionState extends ConsumerState<AdminAdmobSection> {
  late final TextEditingController _bannerController;
  late final TextEditingController _interstitialController;
  late final TextEditingController _rewardedController;
  late final TextEditingController _nativeController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminSettingsControllerProvider);
    _bannerController =
        TextEditingController(text: state.adMobBannerIdOverride);
    _interstitialController =
        TextEditingController(text: state.adMobInterstitialIdOverride);
    _rewardedController =
        TextEditingController(text: state.adMobRewardedIdOverride);
    _nativeController =
        TextEditingController(text: state.adMobNativeIdOverride);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _interstitialController.dispose();
    _rewardedController.dispose();
    _nativeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSettingsControllerProvider);
    final adState = ref.watch(adStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kill Switch Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable Ads for Free Tier',
              style: AdminTokens.bodyStrong(isDark),
            ),
            subtitle: Text(
              'Master kill switch. When enabled, free learners see non-intrusive banner, interstitial, and rewarded ads. Paying learners NEVER see ads regardless of this setting.',
              style: AdminTokens.body(isDark).copyWith(fontSize: 12),
            ),
            value: state.isAdsEnabledForFreeTier,
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              final success = await ref
                  .read(adminSettingsControllerProvider.notifier)
                  .saveSetting('admob_enabled_free_tier', val.toString());
              if (mounted) {
                if (success) {
                  _showSnackBar(
                    val
                        ? 'AdMob ads enabled for free tier! 📢'
                        : 'AdMob ads globally suppressed! 🛑',
                    AppColors.success,
                  );
                } else {
                  _showSnackBar('Failed to update ad state', AppColors.error);
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AdminTokens.divider(isDark)),
          ),

          // 2. Metrics & Revenue Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monetization Telemetry',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AdConfig.isTestMode
                            ? Colors.orange.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AdConfig.isTestMode ? 'TEST MODE' : 'PRODUCTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AdConfig.isTestMode
                              ? Colors.orange
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Total Impressions',
                        value:
                            '${adState.adImpressionCounts.values.fold(0, (a, b) => a + b)}',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Est. Revenue (AdMob API)',
                        value: '₹ 0.00',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Frequency Cap Sliders
          Text('Frequency & Cooldowns', style: AdminTokens.bodyStrong(isDark)),
          const SizedBox(height: 12),

          Text(
            'Interstitial Ad Frequency Cap: ${state.adMobInterstitialCapMinutes} minutes',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Slider(
            value: state.adMobInterstitialCapMinutes.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppColors.primary,
            label: '${state.adMobInterstitialCapMinutes} min',
            onChanged: (val) {
              ref
                  .read(adminSettingsControllerProvider.notifier)
                  .saveSetting(
                    'admob_interstitial_cap_minutes',
                    val.round().toString(),
                  );
            },
          ),
          const SizedBox(height: 8),

          Text(
            'Rewarded Ad Cooldown: ${state.adMobRewardedCooldownMinutes} minutes',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Slider(
            value: state.adMobRewardedCooldownMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            activeColor: AppColors.primary,
            label: '${state.adMobRewardedCooldownMinutes} min',
            onChanged: (val) {
              ref
                  .read(adminSettingsControllerProvider.notifier)
                  .saveSetting(
                    'admob_rewarded_cooldown_minutes',
                    val.round().toString(),
                  );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AdminTokens.divider(isDark)),
          ),

          // 4. Ad Unit ID Overrides
          Text(
            'Ad Unit ID Overrides (Optional)',
            style: AdminTokens.bodyStrong(isDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave blank to use default environment builds / test ad units.',
            style: AdminTokens.body(isDark).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),

          AdminTextField(
            controller: _bannerController,
            label: 'Banner Ad Unit ID',
            hint: 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
            prefixIcon: Icons.view_headline_rounded,
          ),
          const SizedBox(height: 12),

          AdminTextField(
            controller: _interstitialController,
            label: 'Interstitial Ad Unit ID',
            hint: 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
            prefixIcon: Icons.fullscreen_rounded,
          ),
          const SizedBox(height: 12),

          AdminTextField(
            controller: _rewardedController,
            label: 'Rewarded Ad Unit ID',
            hint: 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
            prefixIcon: Icons.stars_rounded,
          ),
          const SizedBox(height: 12),

          AdminTextField(
            controller: _nativeController,
            label: 'Native Ad Unit ID',
            hint: 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
            prefixIcon: Icons.wysiwyg_rounded,
          ),
          const SizedBox(height: 20),

          // Save Button & Ad Inspector Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!kReleaseMode)
                OutlinedButton.icon(
                  onPressed: () {
                    AdService.instance.openAdInspector(context);
                  },
                  icon: const Icon(Icons.bug_report_rounded, size: 18),
                  label: const Text('Open Ad Inspector'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              AdminPrimaryButton(
                label: state.isSaving('admob_banner_id')
                    ? 'Saving Ad IDs…'
                    : 'Save Ad Units',
                icon: Icons.save_rounded,
                onTap: () async {
                  await Future.wait([
                    ref
                        .read(adminSettingsControllerProvider.notifier)
                        .saveSetting(
                          'admob_banner_id',
                          _bannerController.text.trim(),
                        ),
                    ref
                        .read(adminSettingsControllerProvider.notifier)
                        .saveSetting(
                          'admob_interstitial_id',
                          _interstitialController.text.trim(),
                        ),
                    ref
                        .read(adminSettingsControllerProvider.notifier)
                        .saveSetting(
                          'admob_rewarded_id',
                          _rewardedController.text.trim(),
                        ),
                    ref
                        .read(adminSettingsControllerProvider.notifier)
                        .saveSetting(
                          'admob_native_id',
                          _nativeController.text.trim(),
                        ),
                  ]);
                  if (context.mounted) {
                    _showSnackBar(
                      'AdMob unit configuration saved! ✨',
                      AppColors.success,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
