import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that stores and retrieves manual translation and
/// transliteration overrides configured through the Admin Panel.
///
/// Overrides take priority over static dictionaries in [IndicTranslationsDictionary]
/// and [OlChikiMultilingualHelper].
class TranslationOverrideService {
  TranslationOverrideService._();
  static final TranslationOverrideService instance =
      TranslationOverrideService._();

  static const String _meaningsKey = 'olitun_admin_translation_meanings_v1';
  static const String _pronsKey = 'olitun_admin_translation_prons_v1';

  Map<String, Map<String, String>> _meanings = {};
  Map<String, Map<String, String>> _pronunciations = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Loads saved overrides from [SharedPreferences] into memory.
  Future<void> init([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final rawMeanings = p.getString(_meaningsKey);
      if (rawMeanings != null && rawMeanings.isNotEmpty) {
        final decoded = jsonDecode(rawMeanings) as Map<String, dynamic>;
        _meanings = decoded.map(
          (k, v) => MapEntry(
            k.toLowerCase().trim(),
            (v as Map<String, dynamic>).cast<String, String>(),
          ),
        );
      }
      final rawProns = p.getString(_pronsKey);
      if (rawProns != null && rawProns.isNotEmpty) {
        final decoded = jsonDecode(rawProns) as Map<String, dynamic>;
        _pronunciations = decoded.map(
          (k, v) => MapEntry(
            k.toLowerCase().trim(),
            (v as Map<String, dynamic>).cast<String, String>(),
          ),
        );
      }
    } catch (_) {
      // Graceful fallback to empty overrides on parse error
    } finally {
      _isInitialized = true;
    }
  }

  /// Looks up a meaning override for [key] in [targetLang].
  String? getMeaningOverride(String key, String targetLang) {
    final lowerKey = key.toLowerCase().trim();
    final lang = targetLang.toLowerCase().trim();
    return _meanings[lowerKey]?[lang];
  }

  /// Looks up a pronunciation/transliteration override for [key] in [targetLang].
  String? getPronunciationOverride(String key, String targetLang) {
    final lowerKey = key.toLowerCase().trim();
    final lang = targetLang.toLowerCase().trim();
    return _pronunciations[lowerKey]?[lang];
  }

  /// Returns all stored language meanings for a given key.
  Map<String, String> getAllMeanings(String key) {
    final lowerKey = key.toLowerCase().trim();
    return Map<String, String>.from(_meanings[lowerKey] ?? const {});
  }

  /// Returns all stored language pronunciations for a given key.
  Map<String, String> getAllPronunciations(String key) {
    final lowerKey = key.toLowerCase().trim();
    return Map<String, String>.from(_pronunciations[lowerKey] ?? const {});
  }

  /// Persists a custom translation and/or pronunciation for [key] in [langCode].
  Future<void> setOverride({
    required String key,
    required String langCode,
    String? meaning,
    String? pronunciation,
    SharedPreferences? prefs,
  }) async {
    final lowerKey = key.toLowerCase().trim();
    final lang = langCode.toLowerCase().trim();
    if (lowerKey.isEmpty || lang.isEmpty) return;

    if (meaning != null && meaning.trim().isNotEmpty) {
      final langMap = _meanings.putIfAbsent(lowerKey, () => <String, String>{});
      langMap[lang] = meaning.trim();
    } else if (meaning != null && meaning.trim().isEmpty) {
      _meanings[lowerKey]?.remove(lang);
    }

    if (pronunciation != null && pronunciation.trim().isNotEmpty) {
      final langMap =
          _pronunciations.putIfAbsent(lowerKey, () => <String, String>{});
      langMap[lang] = pronunciation.trim();
    } else if (pronunciation != null && pronunciation.trim().isEmpty) {
      _pronunciations[lowerKey]?.remove(lang);
    }

    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setString(_meaningsKey, jsonEncode(_meanings));
      await p.setString(_pronsKey, jsonEncode(_pronunciations));
    } catch (_) {
      // Memory state is updated even if storage write fails
    }
  }

  /// Removes an override for [key] and [langCode].
  Future<void> clearOverride(
    String key,
    String langCode, [
    SharedPreferences? prefs,
  ]) async {
    final lowerKey = key.toLowerCase().trim();
    final lang = langCode.toLowerCase().trim();
    _meanings[lowerKey]?.remove(lang);
    _pronunciations[lowerKey]?.remove(lang);

    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setString(_meaningsKey, jsonEncode(_meanings));
      await p.setString(_pronsKey, jsonEncode(_pronunciations));
    } catch (_) {}
  }
}
