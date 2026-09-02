import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_registry.dart';
import '../models/language_manifest.dart';

const kTargetLanguagePrefKey = 'selected_target_language';
const kDefaultTargetLanguage = 'sat';

final targetLanguageCodeProvider =
    StateNotifierProvider<TargetLanguageNotifier, String>((ref) {
      return TargetLanguageNotifier();
    });

final activeLanguageManifestProvider = Provider<LanguageManifest>((ref) {
  final code = ref.watch(targetLanguageCodeProvider);
  return LanguageRegistry.findByCode(code);
});

class TargetLanguageNotifier extends StateNotifier<String> {
  TargetLanguageNotifier() : super(kDefaultTargetLanguage) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(kTargetLanguagePrefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        state = savedCode;
      }
    } catch (e) {
      // Fall back to default, but surface that the saved selection was lost.
      AppLogger.warning(
        'TargetLanguageNotifier: failed to read saved language: $e',
        name: 'TargetLanguageNotifier',
      );
    }
  }

  Future<void> selectLanguage(String code) async {
    state = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTargetLanguagePrefKey, code);
    } catch (e) {
      // Selection still applies for this session; log the missed write.
      AppLogger.warning(
        'TargetLanguageNotifier: failed to persist language: $e',
        name: 'TargetLanguageNotifier',
      );
    }
  }
}
