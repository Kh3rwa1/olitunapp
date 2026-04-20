import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Translation API configuration.
/// Set TRANSLATE_URL via --dart-define to use Appwrite Function.
/// Falls back to legacy PHP proxy if not provided.
class AiConfig {
  static const String _legacyBaseUrl =
      'https://olitun.in/admin-panel/api/v1';

  /// Appwrite Function URL (or legacy PHP proxy base)
  static const String translateUrl = String.fromEnvironment(
    'TRANSLATE_URL',
    defaultValue: '$_legacyBaseUrl/translate.php',
  );

  static const String reverseTranslateUrl = String.fromEnvironment(
    'REVERSE_TRANSLATE_URL',
    defaultValue: '$_legacyBaseUrl/translate_from_olchiki.php',
  );
}

/// Translation service — Google Translate via server proxy
class AiService {
  final http.Client _client = http.Client();

  /// Translates text to Ol Chiki (Santali) or any target language.
  /// [from] defaults to 'auto' (auto-detect source language).
  /// [to] defaults to 'sat' (Santali / Ol Chiki).
  Future<TranslateResult?> translate(
    String text, {
    String from = 'auto',
    String to = 'sat',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(AiConfig.translateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'from': from, 'to': to}),
      );

      if (response.statusCode == 429) {
        debugPrint('Translation rate limited');
        return TranslateResult(
          translation: 'Rate limit reached. Try again later.',
          isError: true,
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final d = data['data'];
          debugPrint(
            'Translate: "$text" → "${d['translation']}" '
            '(lang: ${d['detectedLanguage']}, cached: ${d['cached']})',
          );
          return TranslateResult(
            translation: d['translation'] ?? '',
            detectedLanguage: d['detectedLanguage'] ?? from,
            cached: d['cached'] == true,
          );
        }
        debugPrint('Translation API error: ${data['message']}');
        return null;
      } else {
        debugPrint('Translation HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return null;
    }
  }

  /// Translates Ol Chiki text to any target language.
  Future<TranslateResult?> translateFromOlChiki(
    String text, {
    String to = 'en',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(AiConfig.reverseTranslateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'to': to}),
      );

      if (response.statusCode == 429) {
        return TranslateResult(
          translation: 'Rate limit reached. Try again later.',
          isError: true,
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final d = data['data'];
          debugPrint('Reverse: "$text" → "${d['translation']}"');
          return TranslateResult(
            translation: d['translation'] ?? '',
            cached: d['cached'] == true,
          );
        }
        return null;
      } else {
        debugPrint(
          'Reverse translate HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Reverse translate error: $e');
      return null;
    }
  }
}

/// Result of a translation call
class TranslateResult {
  final String translation;
  final String? detectedLanguage;
  final bool cached;
  final bool isError;

  TranslateResult({
    required this.translation,
    this.detectedLanguage,
    this.cached = false,
    this.isError = false,
  });
}

final aiServiceProvider = Provider((ref) => AiService());
