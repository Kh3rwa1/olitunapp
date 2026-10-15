import 'package:itun/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../auth/edge_auth.dart';

/// Translation API configuration.
///
/// Translation runs on the Cloudflare Worker (`/api/v1/translate`), which
/// requires a signed-in session. `TRANSLATE_URL` overrides the endpoint for
/// local testing; debug builds without it fail closed so a misconfigured
/// build never silently calls an undeclared host.
class AiConfig {
  static const String _defaultUrl = CloudflareConfig.translateEndpoint;
  static const String _envUrl = String.fromEnvironment('TRANSLATE_URL');

  static String get translateUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kReleaseMode) return _defaultUrl;
    return '';
  }

  static const int maxTranslationChars = 5000;
  static const String _reverseOverride = String.fromEnvironment(
    'REVERSE_TRANSLATE_URL',
  );

  /// Reverse-translate URL — defaults to [translateUrl] so a single
  /// function deployment serves both directions.
  static String get reverseTranslateUrl =>
      _reverseOverride.isNotEmpty ? _reverseOverride : translateUrl;
}

/// Translation service backed by the Cloudflare Worker, which wraps Google
/// Translate and Workers AI IndicTrans2 with caching and rate limiting.
class AiService {
  AiService({http.Client? client, this.defaultEngine, this.edgeAuth})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Signs requests to the Cloudflare Worker, which rejects anonymous calls.
  final EdgeAuth? edgeAuth;

  /// The default translation engine ('cloudflare' | 'google') configured in
  /// the app settings.
  final String? defaultEngine;

  Future<TranslateResult?> translate(
    String text, {
    String from = 'auto',
    String to = 'sat',
    String? engine,
  }) {
    final effectiveEngine = engine ?? defaultEngine;
    return _post(AiConfig.translateUrl, {
      'text': text,
      'from': from,
      'to': to,
      if (effectiveEngine != null && effectiveEngine.isNotEmpty)
        'engine': effectiveEngine,
    }, endpointName: 'translate');
  }

  Future<TranslateResult?> translateFromOlChiki(
    String text, {
    String to = 'en',
    String? engine,
  }) {
    final effectiveEngine = engine ?? defaultEngine;
    return _post(AiConfig.reverseTranslateUrl, {
      'text': text,
      'to': to,
      if (effectiveEngine != null && effectiveEngine.isNotEmpty)
        'engine': effectiveEngine,
    }, endpointName: 'reverseTranslate');
  }

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
        'Translation service is not configured. Build with --dart-define=TRANSLATE_URL=<worker translate endpoint>.',
      );
    }
    try {
      final authHeaders = await edgeAuth?.headers() ?? const <String, String>{};
      final response = await _client.post(
        Uri.parse(url),
        headers: {...authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 429) {
        AppLogger.debug('AiService: 429 rate-limited on $endpointName');
        // Fail closed — surface the error to the caller in all modes.
        return TranslateResult(
          translation: 'Rate limit reached. Please try again later.',
          isError: true,
        );
      }
      if (response.statusCode == 401) {
        return _failClosed('Sign in to use translation.');
      }
      if (response.statusCode != 200) {
        AppLogger.debug(
          'AiService HTTP ${response.statusCode}: ${response.body}',
        );
        return _failClosed(
          'Service error (${response.statusCode}). Please try again.',
        );
      }

      final parsed = _decodeObject(response.body);
      if (parsed == null) {
        return _failClosed('Unexpected response format.');
      }
      if (parsed['success'] != true || parsed['data'] is! Map) {
        AppLogger.debug('AiService API error: ${parsed['message']}');
        return _failClosed('${parsed['message'] ?? 'Translation failed.'}');
      }
      final d = Map<String, dynamic>.from(parsed['data'] as Map);
      return TranslateResult(
        translation: (d['translation'] as String?) ?? '',
        detectedLanguage: d['detectedLanguage'] as String?,
        cached: d['cached'] == true,
        provider: d['provider'] as String?,
      );
    } catch (e) {
      AppLogger.debug('AiService error: $e');
      return _failClosed('Connection error. Please check your network.');
    }
  }

  static TranslateResult _failClosed(String message) {
    return TranslateResult(translation: message, isError: true);
  }

  @visibleForTesting
  static TranslateResult failClosedForTest(String message) =>
      _failClosed(message);
}

Map<String, dynamic>? _decodeObject(String body) {
  try {
    final raw = jsonDecode(body);
    return raw is Map<String, dynamic> ? raw : null;
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
  final String? provider;

  TranslateResult({
    required this.translation,
    this.detectedLanguage,
    this.cached = false,
    this.isError = false,
    this.provider,
  });
}

final aiServiceProvider = Provider((ref) {
  final engine = ref.watch(translationEngineProvider);
  return AiService(defaultEngine: engine, edgeAuth: EdgeAuth.instance);
});
