import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/ads/ad_state.dart';
import '../../../../../core/api/appwrite_db_service.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/storage/hive_service.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../domain/admin_failure.dart';

enum AdminSettingsStatus {
  initial,
  loading,
  loaded,
  saving,
  loadFailure,
  validationFailure,
  saveFailure,
  conflict,
}

class AdminSettingsState {
  const AdminSettingsState({
    required this.status,
    this.onboardingVideoUrl,
    this.globalReviewUnlockEnabled = true,
    this.goalsList = const [],
    this.razorpayKeyId = '',
    this.badgeArcher = 'Santali Archer',
    this.badgeKudum = 'Kudum Master',
    this.badgeKherwal = 'Kherwal Elder',
    this.isAdsEnabledForFreeTier = true,
    this.adMobBannerIdOverride = '',
    this.adMobInterstitialIdOverride = '',
    this.adMobRewardedIdOverride = '',
    this.adMobNativeIdOverride = '',
    this.adMobInterstitialCapMinutes = 3,
    this.adMobRewardedCooldownMinutes = 10,
    this.savingKey,
    this.failure,
    this.isDirty = false,
    this.lastConfirmedState,
  });

  final AdminSettingsStatus status;
  final String? onboardingVideoUrl;
  final bool globalReviewUnlockEnabled;
  final List<Map<String, String>> goalsList;
  final String razorpayKeyId;
  final String badgeArcher;
  final String badgeKudum;
  final String badgeKherwal;
  final bool isAdsEnabledForFreeTier;
  final String adMobBannerIdOverride;
  final String adMobInterstitialIdOverride;
  final String adMobRewardedIdOverride;
  final String adMobNativeIdOverride;
  final int adMobInterstitialCapMinutes;
  final int adMobRewardedCooldownMinutes;
  final String? savingKey;
  final AdminFailure? failure;
  final bool isDirty;
  final AdminSettingsState? lastConfirmedState;

  bool get isLoading => status == AdminSettingsStatus.loading;
  bool get isLoaded => status == AdminSettingsStatus.loaded;
  bool get hasLoadFailure => status == AdminSettingsStatus.loadFailure;
  bool get isSavingAny => status == AdminSettingsStatus.saving;
  bool isSaving(String key) => isSavingAny && savingKey == key;

  AdminSettingsState copyWith({
    AdminSettingsStatus? status,
    String? onboardingVideoUrl,
    bool? globalReviewUnlockEnabled,
    List<Map<String, String>>? goalsList,
    String? razorpayKeyId,
    String? badgeArcher,
    String? badgeKudum,
    String? badgeKherwal,
    bool? isAdsEnabledForFreeTier,
    String? adMobBannerIdOverride,
    String? adMobInterstitialIdOverride,
    String? adMobRewardedIdOverride,
    String? adMobNativeIdOverride,
    int? adMobInterstitialCapMinutes,
    int? adMobRewardedCooldownMinutes,
    String? savingKey,
    AdminFailure? failure,
    bool? isDirty,
    AdminSettingsState? lastConfirmedState,
    bool clearFailure = false,
    bool clearSavingKey = false,
  }) {
    return AdminSettingsState(
      status: status ?? this.status,
      onboardingVideoUrl: onboardingVideoUrl ?? this.onboardingVideoUrl,
      globalReviewUnlockEnabled:
          globalReviewUnlockEnabled ?? this.globalReviewUnlockEnabled,
      goalsList: goalsList ?? this.goalsList,
      razorpayKeyId: razorpayKeyId ?? this.razorpayKeyId,
      badgeArcher: badgeArcher ?? this.badgeArcher,
      badgeKudum: badgeKudum ?? this.badgeKudum,
      badgeKherwal: badgeKherwal ?? this.badgeKherwal,
      isAdsEnabledForFreeTier:
          isAdsEnabledForFreeTier ?? this.isAdsEnabledForFreeTier,
      adMobBannerIdOverride:
          adMobBannerIdOverride ?? this.adMobBannerIdOverride,
      adMobInterstitialIdOverride:
          adMobInterstitialIdOverride ?? this.adMobInterstitialIdOverride,
      adMobRewardedIdOverride:
          adMobRewardedIdOverride ?? this.adMobRewardedIdOverride,
      adMobNativeIdOverride:
          adMobNativeIdOverride ?? this.adMobNativeIdOverride,
      adMobInterstitialCapMinutes:
          adMobInterstitialCapMinutes ?? this.adMobInterstitialCapMinutes,
      adMobRewardedCooldownMinutes:
          adMobRewardedCooldownMinutes ?? this.adMobRewardedCooldownMinutes,
      savingKey: clearSavingKey ? null : (savingKey ?? this.savingKey),
      failure: clearFailure ? null : (failure ?? this.failure),
      isDirty: isDirty ?? this.isDirty,
      lastConfirmedState: lastConfirmedState ?? this.lastConfirmedState,
    );
  }
}

class AdminSettingsController extends AutoDisposeNotifier<AdminSettingsState> {
  @override
  AdminSettingsState build() {
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadSettings);
    return const AdminSettingsState(status: AdminSettingsStatus.initial);
  }

  static const defaultGoals = [
    {
      'id': 'read_ol_chiki',
      'title': 'Read Ol Chiki script',
      'icon': 'translate_rounded',
    },
    {
      'id': 'daily_habits',
      'title': 'Build daily habits',
      'icon': 'calendar_today_rounded',
    },
    {
      'id': 'wealth_mindset',
      'title': 'Grow wealth mindset',
      'icon': 'trending_up_rounded',
    },
    {
      'id': 'binti_guru',
      'title': 'Book Binti Guru services',
      'icon': 'event_note_rounded',
    },
    {
      'id': 'business_santali',
      'title': 'Learn business Santali',
      'icon': 'business_center_rounded',
    },
  ];

  /// Guards against a stale in-flight load clobbering newer local state
  /// (e.g. validation results written after the load was scheduled).
  int _loadSeq = 0;

  /// Loads all remote app settings from Appwrite.
  Future<void> loadSettings() async {
    final seq = ++_loadSeq;
    state = state.copyWith(
      status: AdminSettingsStatus.loading,
      clearFailure: true,
    );

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final docs = await db.listDocuments('app_settings');
      if (seq != _loadSeq) return;

      final settings = <String, dynamic>{};
      for (final doc in docs) {
        final key = doc['settingKey'] as String?;
        if (key != null) {
          settings[key] = doc['settingValue'];
        }
      }

      // Parse goals
      List<Map<String, String>> loadedGoals = [];
      final goalsJsonStr = settings['onboarding_goals'] as String?;
      if (goalsJsonStr != null && goalsJsonStr.trim().isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(goalsJsonStr);
          if (decoded is List) {
            loadedGoals = decoded.map((e) {
              final map = e as Map<String, dynamic>;
              return {
                'id': (map['id'] as String? ?? ''),
                'title': (map['title'] as String? ?? ''),
                'icon': (map['icon'] as String? ?? 'translate_rounded'),
              };
            }).toList();
          }
        } catch (e) {
          AppLogger.warning(
            'AdminSettings: failed to parse onboarding_goals, using defaults: $e',
          );
          loadedGoals = defaultGoals;
        }
      } else {
        loadedGoals = defaultGoals;
      }

      // Read local badge preferences
      final archer = ref.read(badgeTraditionalArcherNameProvider);
      final kudum = ref.read(badgeTraditionalKudumNameProvider);
      final kherwal = ref.read(badgeTraditionalKherwalNameProvider);

      // Read AdMob settings
      final isAdsEnabled = settings['admob_enabled_free_tier'] != 'false';
      final bannerIdOverride = settings['admob_banner_id'] as String? ?? '';
      final interstitialIdOverride =
          settings['admob_interstitial_id'] as String? ?? '';
      final rewardedIdOverride = settings['admob_rewarded_id'] as String? ?? '';
      final nativeIdOverride = settings['admob_native_id'] as String? ?? '';
      final interstitialCap =
          int.tryParse(
            settings['admob_interstitial_cap_minutes']?.toString() ?? '',
          ) ??
          3;
      final rewardedCooldown =
          int.tryParse(
            settings['admob_rewarded_cooldown_minutes']?.toString() ?? '',
          ) ??
          10;

      // Sync with global AdState
      ref.read(adStateProvider.notifier).setGlobalAdsEnabled(isAdsEnabled);
      ref
          .read(adStateProvider.notifier)
          .setInterstitialIntervalMinutes(interstitialCap);
      ref
          .read(adStateProvider.notifier)
          .setRewardedCooldownMinutes(rewardedCooldown);

      final nextState = AdminSettingsState(
        status: AdminSettingsStatus.loaded,
        onboardingVideoUrl: settings['onboarding_video_url'] as String?,
        globalReviewUnlockEnabled:
            settings['global_review_unlock_enabled'] != 'false',
        goalsList: loadedGoals,
        razorpayKeyId: settings['razorpay_key_id'] as String? ?? '',
        badgeArcher: archer,
        badgeKudum: kudum,
        badgeKherwal: kherwal,
        isAdsEnabledForFreeTier: isAdsEnabled,
        adMobBannerIdOverride: bannerIdOverride,
        adMobInterstitialIdOverride: interstitialIdOverride,
        adMobRewardedIdOverride: rewardedIdOverride,
        adMobNativeIdOverride: nativeIdOverride,
        adMobInterstitialCapMinutes: interstitialCap,
        adMobRewardedCooldownMinutes: rewardedCooldown,
      );

      if (seq != _loadSeq) return;
      state = nextState.copyWith(lastConfirmedState: nextState);
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading system settings',
      );
      AppLogger.debug(
        '❌ AdminSettingsController load failed: ${failure.sanitizedDetails}',
      );

      // Never expose fallback defaults as confirmed loaded production values
      state = state.copyWith(
        status: AdminSettingsStatus.loadFailure,
        failure: failure,
      );
    }
  }

  /// Saves a single setting key-value pair to Appwrite DB using strict 404 create fallback.
  Future<bool> saveSetting(String key, String value) async {
    if (state.isSaving(key)) return false;
    ++_loadSeq;

    // Razorpay Key Validation
    if (key == 'razorpay_key_id') {
      final validationErr = validateRazorpayKeyId(value);
      if (validationErr != null) {
        state = state.copyWith(
          status: AdminSettingsStatus.validationFailure,
          failure: AdminValidationFailure(validationErr),
        );
        return false;
      }
    }

    final previousState = state;
    state = state.copyWith(
      status: AdminSettingsStatus.saving,
      savingKey: key,
      clearFailure: true,
    );

    final db = ref.read(appwriteDbServiceProvider);
    final data = {'settingKey': key, 'settingValue': value};

    try {
      try {
        await db.updateDocument('app_settings', key, data);
      } catch (err) {
        final classified = AdminFailure.fromException(err);
        // ONLY create when Appwrite confirms document not found (404)
        if (classified is AdminNotFoundFailure) {
          await db.createDocument('app_settings', key, data);
        } else {
          // Re-throw non-404 errors (network, permission 401/403, 500, etc.)
          throw classified;
        }
      }

      // Update state upon confirmed backend persistence
      AdminSettingsState updated = state.copyWith(
        status: AdminSettingsStatus.loaded,
        clearSavingKey: true,
        clearFailure: true,
        isDirty: false,
      );

      if (key == 'onboarding_video_url') {
        updated = updated.copyWith(
          onboardingVideoUrl: value.isEmpty ? null : value,
        );
      } else if (key == 'global_review_unlock_enabled') {
        updated = updated.copyWith(
          globalReviewUnlockEnabled: value.toLowerCase() != 'false',
        );
      } else if (key == 'razorpay_key_id') {
        updated = updated.copyWith(razorpayKeyId: value);
      } else if (key == 'admob_enabled_free_tier') {
        final enabled = value.toLowerCase() != 'false';
        updated = updated.copyWith(isAdsEnabledForFreeTier: enabled);
        ref.read(adStateProvider.notifier).setGlobalAdsEnabled(enabled);
      } else if (key == 'admob_banner_id') {
        updated = updated.copyWith(adMobBannerIdOverride: value);
      } else if (key == 'admob_interstitial_id') {
        updated = updated.copyWith(adMobInterstitialIdOverride: value);
      } else if (key == 'admob_rewarded_id') {
        updated = updated.copyWith(adMobRewardedIdOverride: value);
      } else if (key == 'admob_native_id') {
        updated = updated.copyWith(adMobNativeIdOverride: value);
      } else if (key == 'admob_interstitial_cap_minutes') {
        final cap = int.tryParse(value) ?? 3;
        updated = updated.copyWith(adMobInterstitialCapMinutes: cap);
        ref.read(adStateProvider.notifier).setInterstitialIntervalMinutes(cap);
      } else if (key == 'admob_rewarded_cooldown_minutes') {
        final cd = int.tryParse(value) ?? 10;
        updated = updated.copyWith(adMobRewardedCooldownMinutes: cd);
        ref.read(adStateProvider.notifier).setRewardedCooldownMinutes(cd);
      }

      state = updated.copyWith(lastConfirmedState: updated);
      ref.invalidate(appSettingsProvider);
      return true;
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Saving setting ($key)',
      );
      AppLogger.debug(
        '❌ AdminSettingsController save ($key) failed: ${failure.sanitizedDetails}',
      );

      // Rollback visible state to last confirmed snapshot
      state = (previousState.lastConfirmedState ?? previousState).copyWith(
        status: AdminSettingsStatus.saveFailure,
        clearSavingKey: true,
        failure: failure,
      );
      return false;
    }
  }

  /// Updates and saves onboarding learning goals.
  Future<bool> saveGoals(List<Map<String, String>> goals) async {
    ++_loadSeq;
    for (final g in goals) {
      final title = g['title']?.trim() ?? '';
      if (title.isEmpty) {
        state = state.copyWith(
          status: AdminSettingsStatus.validationFailure,
          failure: const AdminValidationFailure('Goal titles cannot be empty.'),
        );
        return false;
      }
    }

    final jsonStr = jsonEncode(goals);
    final success = await saveSetting('onboarding_goals', jsonStr);
    if (success) {
      state = state.copyWith(goalsList: goals);
    }
    return success;
  }

  /// Saves traditional badge names to SharedPreferences and Riverpod state.
  Future<bool> saveBadgeNames({
    required String archer,
    required String kudum,
    required String kherwal,
  }) async {
    ++_loadSeq;
    final a = archer.trim();
    final k = kudum.trim();
    final kh = kherwal.trim();

    if (a.isEmpty || k.isEmpty || kh.isEmpty) {
      state = state.copyWith(
        status: AdminSettingsStatus.validationFailure,
        failure: const AdminValidationFailure('Badge names cannot be empty.'),
      );
      return false;
    }

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('badge_traditional_archer_name', a);
      await prefs.setString('badge_traditional_kudum_name', k);
      await prefs.setString('badge_traditional_kherwal_name', kh);

      ref.read(badgeTraditionalArcherNameProvider.notifier).state = a;
      ref.read(badgeTraditionalKudumNameProvider.notifier).state = k;
      ref.read(badgeTraditionalKherwalNameProvider.notifier).state = kh;

      final updated = state.copyWith(
        badgeArcher: a,
        badgeKudum: k,
        badgeKherwal: kh,
        status: AdminSettingsStatus.loaded,
        clearFailure: true,
      );
      state = updated.copyWith(lastConfirmedState: updated);
      return true;
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Saving badge names',
      );
      state = state.copyWith(
        status: AdminSettingsStatus.saveFailure,
        failure: failure,
      );
      return false;
    }
  }

  void markDirty(bool dirty) {
    if (state.isDirty != dirty) {
      state = state.copyWith(isDirty: dirty);
    }
  }

  /// Validates Razorpay Key ID string.
  /// Must start with `rzp_test_` or `rzp_live_`. Rejects secrets or invalid formats.
  static String? validateRazorpayKeyId(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return null; // Blank is allowed to use bundled fallback
    }

    if (trimmed.toLowerCase().startsWith('rzp_sec_')) {
      return 'Rejected: You entered a Razorpay Secret Key. Only publishable Key ID (rzp_live_... or rzp_test_...) is allowed in client configuration.';
    }

    if (!trimmed.startsWith('rzp_test_') && !trimmed.startsWith('rzp_live_')) {
      return 'Invalid Key ID format. Razorpay Key ID must start with "rzp_test_" or "rzp_live_".';
    }

    if (trimmed.length < 16 || trimmed.length > 64) {
      return 'Invalid Key ID length. Razorpay Key ID must be between 16 and 64 characters.';
    }

    return null;
  }
}

final adminSettingsControllerProvider =
    NotifierProvider.autoDispose<AdminSettingsController, AdminSettingsState>(
      AdminSettingsController.new,
    );
