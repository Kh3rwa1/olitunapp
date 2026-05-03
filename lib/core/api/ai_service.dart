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
/// Two URL shapes are supported:
///
/// 1. **Function HTTP endpoint** (recommended; returns the function's body
///    directly with status 200):
///      https://<id>.<region>.appwrite.run/
///
/// 2. **Executions REST API** (returns 201 + an Execution object whose
///    `responseBody` field is the actual function response):
///      https://<region>.cloud.appwrite.io/v1/functions/<id>/executions
///
/// [_post] auto-detects the wrapper shape and parses both correctly.
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
      // Function HTTP endpoint returns 200; the Executions REST API
      // returns 201 with an Execution object wrapping the body.
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('AiService HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final parsed = _unwrapAppwriteExecution(response.body);
      if (parsed == null) return null;
      if (parsed['success'] != true || parsed['data'] == null) {
        debugPrint('AiService API error: ${parsed['message']}');
        return null;
      }
      final d = parsed['data'] as Map<String, dynamic>;
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

  /// If the response body is an Appwrite Execution object (created by the
  /// `/v1/functions/<id>/executions` endpoint), returns the inner JSON
  /// response that the function itself produced. Otherwise returns the
  /// body parsed as JSON.
  @visibleForTesting
  static Map<String, dynamic>? unwrapAppwriteExecution(String body) =>
      _unwrapAppwriteExecution(body);
}

Map<String, dynamic>? _unwrapAppwriteExecution(String body) {
  try {
    final raw = jsonDecode(body);
    if (raw is! Map<String, dynamic>) return null;
    // An Appwrite Execution has $id + status + responseBody fields.
    if (raw.containsKey('responseBody') && raw.containsKey('status')) {
      final inner = raw['responseBody'];
      if (inner is String && inner.isNotEmpty) {
        final innerJson = jsonDecode(inner);
        return innerJson is Map<String, dynamic> ? innerJson : null;
      }
      return null;
    }
    return raw;
  } catch (e) {
    debugPrint('AiService: response parse failed: $e');
    return null;
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
