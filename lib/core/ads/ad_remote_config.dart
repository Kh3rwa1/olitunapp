import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_settings_provider.dart';
import '../config/ad_config.dart';
import 'ad_state.dart';

/// Applies the admin AdMob settings (`app_settings` collection) to every
/// learner, not only to admins who open the settings screen. Watched once
/// from the app root.
final adRemoteConfigSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Map<String, dynamic>>>(appSettingsProvider, (_, next) {
    final settings = next.valueOrNull;
    if (settings == null || settings.isEmpty) return;
    applyAdRemoteSettings(ref.read(adStateProvider.notifier), settings);
  }, fireImmediately: true);
});

/// Pure mapping from settings to ad state, shared with the admin screen.
void applyAdRemoteSettings(
  AdStateNotifier notifier,
  Map<String, dynamic> settings,
) {
  String text(String key) => settings[key]?.toString().trim() ?? '';
  int? minutes(String key) => int.tryParse(text(key));

  notifier.setGlobalAdsEnabled(
    text('admob_enabled_free_tier').toLowerCase() != 'false',
  );
  notifier.setInterstitialIntervalMinutes(
    minutes('admob_interstitial_cap_minutes') ??
        AdConfig.defaultInterstitialIntervalMinutes,
  );
  notifier.setRewardedCooldownMinutes(
    minutes('admob_rewarded_cooldown_minutes') ??
        AdConfig.defaultRewardedCooldownMinutes,
  );
  notifier.setAppOpenIntervalMinutes(
    minutes('admob_app_open_cap_minutes') ??
        AdConfig.defaultAppOpenIntervalMinutes,
  );

  AdConfig.applyRemoteUnitIds({
    'banner': text('admob_banner_id'),
    'interstitial': text('admob_interstitial_id'),
    'rewarded': text('admob_rewarded_id'),
    'native': text('admob_native_id'),
    'app_open': text('admob_app_open_id'),
  });
}
