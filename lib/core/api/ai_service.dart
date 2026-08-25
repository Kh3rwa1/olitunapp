import 'package:itun/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:itun/core/config/appwrite_config.dart';
import '../auth/appwrite_auth_service.dart';

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
///      https://[id].[region].appwrite.run/
///
/// 2. **Executions REST API** (returns 201 + an Execution object whose
///    `responseBody` field is the actual function response):
///      https://[region].cloud.appwrite.io/v1/functions/[id]/executions
///
/// [_post] auto-detects the wrapper shape and parses both correctly.
///
/// Reverse translation uses the same function by default; only set
/// `REVERSE_TRANSLATE_URL` if you have intentionally split it out into a
/// separate deployment.
class AiConfig {
  static const String translateUrl = String.fromEnvironment('TRANSLATE_URL');
  static const int maxTranslationChars = 5000;
  static const String _reverseOverride = String.fromEnvironment(
    'REVERSE_TRANSLATE_URL',
  );

  /// Reverse-translate URL — defaults to [translateUrl] so a single
  /// function deployment serves both directions.
  static String get reverseTranslateUrl =>
      _reverseOverride.isNotEmpty ? _reverseOverride : translateUrl;
}

/// Translation service — talks to the Appwrite Function deployed under
/// `functions/translator/`. The function wraps Google Translate with
/// caching + rate limiting (see that directory's README).
class AiService {
  AiService({http.Client? client, this.functions})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// When provided, executions go through the Appwrite SDK so the user's
  /// session authenticates the call (the function requires `users` execute
  /// permission). Raw-HTTP fallback remains for web-cookie contexts.
  final Functions? functions;

  Future<TranslateResult?> translate(
    String text, {
    String from = 'auto',
    String to = 'sat',
  }) => _post(AiConfig.translateUrl, {
    'text': text,
    'from': from,
    'to': to,
  }, endpointName: 'translate');

  Future<TranslateResult?> translateFromOlChiki(
    String text, {
    String to = 'en',
  }) => _post(AiConfig.reverseTranslateUrl, {
    'text': text,
    'to': to,
  }, endpointName: 'reverseTranslate');

  @visibleForTesting
  Future<TranslateResult?> translateFromUrlForTest(
    String url,
    Map<String, dynamic> body,
  ) => _post(url, body, endpointName: 'testTranslate');

  Future<TranslateResult?> _post(
    String url,
    Map<String, dynamic> body, {
    required String endpointName,
  }) async {
    final text = (body['text'] as String?)?.trim() ?? '';
    if (text.length > AiConfig.maxTranslationChars) {
      return TranslateResult(
        translation:
            'Text is too long. Keep translations under ${AiConfig.maxTranslationChars} characters.',
        isError: true,
      );
    }
    if (url.isEmpty) {
      return _failClosed(
        'Translation service is not configured. Build with --dart-define=TRANSLATE_URL=[appwrite-function-execution-url].',
      );
    }
    try {
      // Preferred path: SDK execution with session auth. The function's
      // execute permission is ['users'], so bare HTTP can never pass.
      final execMatch = RegExp(
        r'/functions/([^/]+)/executions',
      ).firstMatch(url);
      if (functions != null && execMatch != null) {
        return _executeViaSdk(
          functions!,
          execMatch.group(1)!,
          body,
          endpointName: endpointName,
        );
      }

      final requestBody = url.contains('/executions')
          ? jsonEncode({'body': jsonEncode(body), 'async': false})
          : jsonEncode(body);

      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': AppwriteConfig.projectId,
        },
        body: requestBody,
      );

      if (response.statusCode == 429) {
        AppLogger.debug('AiService: 429 rate-limited on $endpointName');
        // Fail closed — surface the error to the caller in all modes.
        return TranslateResult(
          translation: 'Rate limit reached. Please try again later.',
          isError: true,
        );
      }
      // Function HTTP endpoint returns 200; the Executions REST API
      // returns 201 with an Execution object wrapping the body.
      if (response.statusCode != 200 && response.statusCode != 201) {
        AppLogger.debug(
          'AiService HTTP ${response.statusCode}: ${response.body}',
        );
        return _failClosed(
          'Service error (${response.statusCode}). Please try again.',
        );
      }

      final parsed = _unwrapAppwriteExecution(response.body);
      if (parsed == null) {
        return _failClosed('Unexpected response format.');
      }

      final int? innerStatusCode = parsed['_appwriteStatusCode'] as int?;
      if (innerStatusCode == 429 || response.statusCode == 429) {
        AppLogger.debug('AiService: 429 rate-limited on $endpointName');
        return TranslateResult(
          translation: 'Rate limit reached. Please try again later.',
          isError: true,
        );
      }

      if (parsed['success'] != true || parsed['data'] == null) {
        AppLogger.debug('AiService API error: ${parsed['message']}');
        return _failClosed('${parsed['message'] ?? 'Translation failed.'}');
      }
      final d = parsed['data'] as Map<String, dynamic>;
      return TranslateResult(
        translation: (d['translation'] as String?) ?? '',
        detectedLanguage: d['detectedLanguage'] as String?,
        cached: d['cached'] == true,
      );
    } catch (e) {
      AppLogger.debug('AiService error: $e');
      return _failClosed('Connection error. Please check your network.');
    }
  }

  /// In production (release mode), never return null — always surface an
  /// error result so the UI can display a user-facing message.
  /// Only debug mode is lenient (returns null → retryable).
  Future<TranslateResult?> _executeViaSdk(
    Functions functions,
    String functionId,
    Map<String, dynamic> body, {
    required String endpointName,
  }) async {
    final execution = await functions.createExecution(
      functionId: functionId,
      body: jsonEncode(body),
      xasync: false,
    );

    final innerStatus = execution.responseStatusCode;
    if (innerStatus == 429) {
      AppLogger.debug('AiService: 429 rate-limited on $endpointName');
      return TranslateResult(
        translation: 'Rate limit reached. Please try again later.',
        isError: true,
      );
    }
    if (innerStatus != 200 && innerStatus != 201) {
      AppLogger.debug('AiService execution $endpointName HTTP $innerStatus');
      return _failClosed('Service error ($innerStatus). Please try again.');
    }

    final parsed = _unwrapAppwriteExecution(execution.responseBody);
    if (parsed == null) {
      return _failClosed('Unexpected response format.');
    }
    if (parsed['success'] != true || parsed['data'] == null) {
      AppLogger.debug('AiService API error: ${parsed['message']}');
      return _failClosed('${parsed['message'] ?? 'Translation failed.'}');
    }
    final d = parsed['data'] as Map<String, dynamic>;
    return TranslateResult(
      translation: (d['translation'] as String?) ?? '',
      detectedLanguage: d['detectedLanguage'] as String?,
      cached: d['cached'] == true,
    );
  }

  static TranslateResult _failClosed(String message) {
    return TranslateResult(translation: message, isError: true);
  }

  @visibleForTesting
  static TranslateResult failClosedForTest(String message) =>
      _failClosed(message);

  /// If the response body is an Appwrite Execution object (created by the
  /// `/v1/functions/[id]/executions` endpoint), returns the inner JSON
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
      final statusCode = raw['responseStatusCode'];

      if (inner is String && inner.isNotEmpty) {
        try {
          final innerJson = jsonDecode(inner);
          if (innerJson is Map<String, dynamic>) {
            innerJson['_appwriteStatusCode'] = statusCode;
            return innerJson;
          }
        } catch (_) {
          // If JSON decode fails, just return the string wrapped
        }
        return {'_appwriteStatusCode': statusCode, 'message': inner};
      }
      return null;
    }
    return raw;
  } catch (e) {
    AppLogger.debug('AiService: response parse failed: $e');
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

final aiServiceProvider = Provider((ref) {
  final auth = ref.watch(appwriteAuthServiceProvider);
  return AiService(functions: Functions(auth.client));
});
