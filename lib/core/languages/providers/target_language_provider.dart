import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_registry.dart';
import '../models/language_manifest.dart';

const kTargetLanguagePrefKey = 'selected_target_language';
const kDefaultTargetLanguage = 'sat';

final targetLanguageCodeProvider =
    NotifierProvider<TargetLanguageNotifier, String>(
      TargetLanguageNotifier.new,
    );

final activeLanguageManifestProvider = Provider<LanguageManifest>((ref) {
  final code = ref.watch(targetLanguageCodeProvider);
  return LanguageRegistry.findByCode(code);
});

class TargetLanguageNotifier extends Notifier<String> {
  TargetLanguageNotifier([this._initial = kDefaultTargetLanguage]);

  final String _initial;

  /// Bumped on dispose so a storage read that resolves afterwards is dropped.
  int _generation = 0;

  @override
  String build() {
    ref.onDispose(() => _generation++);
    _loadFromStorage(_generation);
    return _initial;
  }

  Future<void> _loadFromStorage(int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(kTargetLanguagePrefKey);
      if (generation != _generation) return;
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
