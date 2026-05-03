import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Translation API configuration.
///
/// Set the URL of the deployed Appwrite Function via build flag. There is
/// no default value — calling [AiService.translate] without a configured
/// URL will throw at request time, surfacing the misconfiguration rather
/// than silently leaking traffic to an undeclared host.
///
///   --dart-define=TRANSLATE_URL=https://<region>.appwrite.network/v1/functions/<id>/executions
///
/// Reverse translation uses the same function by default; only set
/// `REVERSE_TRANSLATE_URL` if you have intentionally split it out into a
/// separate deployment.
class AiConfig {
  static const String translateUrl = String.fromEnvironment('TRANSLATE_URL');
  static const String _reverseOverride =
      String.fromEnvironment('REVERSE_TRANSLATE_URL');

  /// Reverse-translate URL — defaults to [translateUrl] so a single
  /// function deployment serves both directions.
  static String get reverseTranslateUrl =>
      _reverseOverride.isNotEmpty ? _reverseOverride : translateUrl;
}

/// Translation service — talks to the Appwrite Function deployed under
/// `functions/translator/`. The function wraps Google Translate with
/// caching + rate limiting (see that directory's README).
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<TranslateResult?> translate(
    String text, {
    String from = 'auto',
    String to = 'sat',
  }) =>
      _post(
        AiConfig.translateUrl,
        {'text': text, 'from': from, 'to': to},
        endpointName: 'translate',
      );

  Future<TranslateResult?> translateFromOlChiki(
    String text, {
    String to = 'en',
  }) =>
      _post(
        AiConfig.reverseTranslateUrl,
        {'text': text, 'to': to},
        endpointName: 'reverseTranslate',
      );

  Future<TranslateResult?> _post(
    String url,
    Map<String, dynamic> body, {
    required String endpointName,
  }) async {
    if (url.isEmpty) {
      throw StateError(
        'AiService.$endpointName called without a configured URL. '
        'Build with --dart-define=TRANSLATE_URL=<appwrite-function-execution-url>.',
      );
    }
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 429) {
        return TranslateResult(
          translation: 'Rate limit reached. Try again later.',
          isError: true,
        );
      }
      if (response.statusCode != 200) {
        debugPrint('AiService HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true || data['data'] == null) {
        debugPrint('AiService API error: ${data['message']}');
        return null;
      }
      final d = data['data'] as Map<String, dynamic>;
      return TranslateResult(
        translation: (d['translation'] as String?) ?? '',
        detectedLanguage: d['detectedLanguage'] as String?,
        cached: d['cached'] == true,
      );
    } catch (e) {
      debugPrint('AiService error: $e');
      return null;
    }
  }
}

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
