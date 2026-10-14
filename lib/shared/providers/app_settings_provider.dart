import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/config/appwrite_config.dart';
import '../../core/config/cloudflare_config.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

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

/// Injected HTTP client for testing app settings edge queries.
final appSettingsHttpClientProvider = Provider<http.Client?>((ref) => null);

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(isAuthenticatedProvider);
  final client = ref.watch(appSettingsHttpClientProvider) ?? http.Client();
  final db = ref.read(appwriteDbServiceProvider);

  // 1. Try Cloudflare Workers Edge API (Global edge caching, zero Appwrite reads)
  try {
    final uri = Uri.parse(CloudflareConfig.settingsEndpoint);
    final res = await client.get(uri).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body['ok'] == true) {
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
        if (settings.isNotEmpty) {
          return settings;
        }
      }
    }
  } catch (e) {
    AppLogger.debug('Cloudflare settings fetch bypassed: $e');
  }

  // 2. Resilient Appwrite DB fallback
  try {
    final docs = await db.listDocuments('app_settings');
    final settings = <String, dynamic>{};
    for (final doc in docs) {
      settings[doc['settingKey'] as String] = doc['settingValue'];
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
