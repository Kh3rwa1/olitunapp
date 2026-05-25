import 'dart:convert';
import 'package:itun/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/config/appwrite_config.dart';
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

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(isAuthenticatedProvider);
  try {
    final db = ref.read(appwriteDbServiceProvider);
    final docs = await db.listDocuments('app_settings');
    final settings = <String, dynamic>{};
    for (final doc in docs) {
      settings[doc['settingKey'] as String] = doc['settingValue'];
    }
    return settings;
  } catch (e) {
    AppLogger.debug('Failed to load app settings: $e');
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
        } catch (e) {
          AppLogger.debug('Error decoding onboarding_goals from settings: $e');
        }
      }
      return _defaultGoals;
    },
    orElse: () => _defaultGoals,
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
