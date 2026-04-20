import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final db = ref.read(appwriteDbServiceProvider);
    final docs = await db.listDocuments('app_settings');
    final settings = <String, dynamic>{};
    for (final doc in docs) {
      settings[doc['settingKey'] as String] = doc['settingValue'];
    }
    return settings;
  } catch (e) {
    debugPrint('Failed to load app settings: $e');
    return <String, dynamic>{};
  }
});

final onboardingVideoUrlProvider = Provider<String?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.whenOrNull(
    data: (data) => data['onboarding_video_url'] as String?,
  );
});
