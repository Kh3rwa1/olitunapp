import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import '../api/edge_json_client.dart';
import 'appwrite_config.dart';
import 'cloudflare_config.dart';
import '../auth/auth_providers.dart';

class OnboardingGoal {
  final String id;
  final String title;
  final String icon;

  OnboardingGoal({required this.id, required this.title, required this.icon});

  factory OnboardingGoal.fromJson(Map<String, dynamic> json) {
    return OnboardingGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'icon': icon};
  }
}

/// HTTP client for app settings Worker reads (overridable in tests).
final appSettingsHttpClientProvider = Provider<http.Client>(
  (ref) => ref.watch(edgeHttpClientProvider),
);

/// Remote app settings from the Cloudflare Worker. An empty settings map is
/// a valid result; a failed request yields an empty map so callers fall back
/// to their defaults.
final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(isAuthenticatedProvider);
  final client = ref.watch(appSettingsHttpClientProvider);

  try {
    final body = await EdgeJsonClient.getJson(
      client,
      Uri.parse(CloudflareConfig.settingsEndpoint),
      timeout: const Duration(seconds: 4),
    );
    final settings = <String, dynamic>{};
    if (body['settings'] is Map) {
      final map = body['settings'] as Map;
      for (final entry in map.entries) {
        settings[entry.key.toString()] = entry.value;
      }
    }
    if (body['documents'] is List) {
      for (final doc in body['documents']) {
        if (doc is Map) {
          final key = doc['settingKey'] ?? doc['setting_key'];
          final val = doc['settingValue'] ?? doc['setting_value'];
          if (key != null && val != null) {
            settings[key.toString()] = val;
          }
        }
      }
    }
    return settings;
  } catch (e, stack) {
    AppLogger.warning(
      'Failed to load app settings',
      name: 'AppSettings',
      error: e,
      stackTrace: stack,
    );
    return <String, dynamic>{};
  }
});

final onboardingVideoUrlProvider = Provider<String?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.whenOrNull(
    data: (data) => data['onboarding_video_url'] as String?,
  );
});

final razorpayKeyProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.maybeWhen(
    data: (settings) {
      final key = settings['razorpay_key_id'] as String?;
      if (key != null && key.trim().isNotEmpty) {
        return key.trim();
      }
      return AppwriteConfig.razorpayKeyId;
    },
    orElse: () => AppwriteConfig.razorpayKeyId,
  );
});

final onboardingGoalsProvider = Provider<List<OnboardingGoal>>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.maybeWhen(
    data: (settings) {
      final goalsJsonStr = settings['onboarding_goals'] as String?;
      if (goalsJsonStr != null && goalsJsonStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(goalsJsonStr);
          return decoded
              .map((e) => OnboardingGoal.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e, stack) {
          AppLogger.warning(
            'Error decoding onboarding_goals from settings',
            name: 'AppSettings',
            error: e,
            stackTrace: stack,
          );
        }
      }
      return _defaultGoals;
    },
    orElse: () => _defaultGoals,
  );
});

final translationEngineProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.maybeWhen(
    data: (settings) =>
        (settings['translation_engine'] as String?)?.toLowerCase().trim() ??
        'google',
    orElse: () => 'google',
  );
});

final List<OnboardingGoal> _defaultGoals = [
  OnboardingGoal(
    id: 'read_ol_chiki',
    title: 'Read Ol Chiki script',
    icon: 'translate_rounded',
  ),
  OnboardingGoal(
    id: 'daily_habits',
    title: 'Build daily habits',
    icon: 'calendar_today_rounded',
  ),
  OnboardingGoal(
    id: 'wealth_mindset',
    title: 'Grow wealth mindset',
    icon: 'trending_up_rounded',
  ),
  OnboardingGoal(
    id: 'binti_guru',
    title: 'Book Binti Guru services',
    icon: 'event_note_rounded',
  ),
  OnboardingGoal(
    id: 'business_santali',
    title: 'Learn business Santali',
    icon: 'business_center_rounded',
  ),
];
