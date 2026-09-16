import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'bodhan_voice_catalog.dart';

/// Santali voice (Bodhan indic-speak) configuration.
///
/// The Bodhan API keys NEVER live in the app. They are stored as documents
/// in the Appwrite `bodhan_api_keys` collection and the `santaliVoice`
/// function rotates through them server-side when a key runs out of
/// credit. The client only needs the function's execution URL.
///
/// Provide it with:
///   --dart-define=SANTALI_VOICE_URL=https://REGION.cloud.appwrite.io/v1/functions/FUNCTION_ID/executions
/// or (recommended, authenticated calls):
///   --dart-define=SANTALI_VOICE_FUNCTION_ID=FUNCTION_ID
class SantaliVoiceConfig {
  static const String _envUrl = String.fromEnvironment('SANTALI_VOICE_URL');
  static const String _envFunctionId = String.fromEnvironment(
    'SANTALI_VOICE_FUNCTION_ID',
  );

  /// Max characters per generation (matches the function's cap and keeps
  /// each request inside Bodhan's ~30s audio guidance).
  static const int maxChars = 600;

  static String get functionId => _envFunctionId;

  static String get executionUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (_envFunctionId.isNotEmpty) {
      final endpoint = AppwriteConfig.endpoint.replaceAll(
        RegExp(r'/v1/?$'),
        '',
      );
      if (endpoint.isNotEmpty && !endpoint.contains('example.invalid')) {
        return '$endpoint/v1/functions/$_envFunctionId/executions';
      }
    }
    return '';
  }
}

/// A generated voice clip.
class VoiceClip {
  const VoiceClip({
    required this.audioUrl,
    required this.voice,
    required this.lang,
    required this.style,
    required this.chars,
    required this.cached,
    this.storageFileId,
  });

  final String audioUrl;
  final String voice;
  final String lang;
  final String style;
  final int chars;
  final bool cached;
  final String? storageFileId;
}

/// Failure from the voice pipeline. [loginRequired] drives the sign-in CTA.
class VoiceFailure {
  const VoiceFailure(this.message, {this.loginRequired = false});

  final String message;
  final bool loginRequired;
}

/// Talks to the `santaliVoice` Appwrite Function. Mirrors [AiService]'s
/// execution handling: SDK path with session auth when available, raw-HTTP
/// fallback for web-cookie contexts.
class SantaliTtsService {
  SantaliTtsService({http.Client? client, this.functions})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Functions? functions;

  Future<({VoiceClip? clip, VoiceFailure? failure})> synthesize({
    required String text,
    required String voice,
    String lang = defaultVoiceLang,
    String style = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return (clip: null, failure: const VoiceFailure('Type something first.'));
    }
    if (trimmed.length > SantaliVoiceConfig.maxChars) {
      return (
        clip: null,
        failure: const VoiceFailure(
          'Keep it under ${SantaliVoiceConfig.maxChars} characters — Bodhan reads a sentence or two at a time.',
        ),
      );
    }
    if (!isKnownVoice(voice)) {
      return (clip: null, failure: VoiceFailure('Unknown voice: $voice.'));
    }
    if (!isKnownStyle(style)) {
      return (clip: null, failure: const VoiceFailure('Unknown style.'));
    }

    final body = {
      'text': trimmed,
      'voice': voice,
      'lang': lang,
      'style': style,
    };
    final url = SantaliVoiceConfig.executionUrl;
    if (SantaliVoiceConfig.functionId.isEmpty && url.isEmpty) {
      return (
        clip: null,
        failure: const VoiceFailure(
          'Voice service is not configured yet. Build with --dart-define=SANTALI_VOICE_FUNCTION_ID=<id>.',
        ),
      );
    }

    try {
      // Preferred: SDK execution with the user's session.
      final execMatch = RegExp(
        r'/functions/([^/]+)/executions',
      ).firstMatch(url);
      final functionId = SantaliVoiceConfig.functionId.isNotEmpty
          ? SantaliVoiceConfig.functionId
          : (execMatch != null ? execMatch.group(1)! : '');
      if (functions != null && functionId.isNotEmpty) {
        return await _synthesizeViaSdk(functions!, functionId, body);
      }
      if (url.isEmpty) {
        return (
          clip: null,
          failure: const VoiceFailure('Voice service is not configured yet.'),
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
      if (response.statusCode != 200 && response.statusCode != 201) {
        return (clip: null, failure: _httpFailure(response.statusCode));
      }
      return _parseFunctionPayload(response.body);
    } catch (e) {
      AppLogger.debug('SantaliTtsService error: $e');
      return (
        clip: null,
        failure: const VoiceFailure(
          'Connection error. Check your network and try again.',
        ),
      );
    }
  }

  Future<({VoiceClip? clip, VoiceFailure? failure})> _synthesizeViaSdk(
    Functions functions,
    String functionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final execution = await functions.createExecution(
        functionId: functionId,
        body: jsonEncode(body),
        xasync: false,
      );
      if (execution.responseStatusCode == 401) {
        return (
          clip: null,
          failure: const VoiceFailure(
            'Sign in to create voice clips.',
            loginRequired: true,
          ),
        );
      }
      if (execution.responseStatusCode != 200 &&
          execution.responseStatusCode != 201) {
        return (
          clip: null,
          failure: _httpFailure(execution.responseStatusCode),
        );
      }
      return _parseFunctionPayload(execution.responseBody);
    } on AppwriteException catch (e) {
      AppLogger.debug('SantaliTtsService SDK error: ${e.message}');
      if (e.code == 401) {
        return (
          clip: null,
          failure: const VoiceFailure(
            'Sign in to create voice clips.',
            loginRequired: true,
          ),
        );
      }
      return (
        clip: null,
        failure: VoiceFailure(
          'Voice service error (${e.code ?? 'unknown'}). Try again.',
        ),
      );
    }
  }

  VoiceFailure _httpFailure(int status) {
    if (status == 401) {
      return const VoiceFailure(
        'Sign in to create voice clips.',
        loginRequired: true,
      );
    }
    if (status == 429) {
      return const VoiceFailure('Voice is busy. Try again in a moment.');
    }
    if (status == 503) {
      return const VoiceFailure(
        'Voice service is busy. Try again in a moment.',
      );
    }
    return VoiceFailure('Voice service error ($status). Try again.');
  }

  ({VoiceClip? clip, VoiceFailure? failure}) _parseFunctionPayload(String raw) {
    final parsed = _unwrapExecution(raw);
    if (parsed == null) {
      return (
        clip: null,
        failure: const VoiceFailure('Unexpected voice response. Try again.'),
      );
    }
    if (parsed['success'] != true || parsed['data'] is! Map) {
      final code = parsed['error'] as String?;
      final message =
          parsed['message'] as String? ?? 'Voice generation failed.';
      if (code == 'LOGIN_REQUIRED') {
        return (
          clip: null,
          failure: VoiceFailure(message, loginRequired: true),
        );
      }
      if (code == 'INPUT_TOO_LONG' ||
          code == 'INVALID_INPUT' ||
          code == 'UNSUPPORTED_VOICE' ||
          code == 'UNSUPPORTED_STYLE' ||
          code == 'UPSTREAM_REJECTED') {
        return (clip: null, failure: VoiceFailure(message));
      }
      return (clip: null, failure: VoiceFailure(message));
    }
    final d = parsed['data'] as Map;
    final audioUrl = d['audioUrl'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      return (
        clip: null,
        failure: const VoiceFailure('Voice came back empty. Try again.'),
      );
    }
    return (
      clip: VoiceClip(
        audioUrl: audioUrl,
        voice: d['voice'] as String? ?? '',
        lang: d['lang'] as String? ?? defaultVoiceLang,
        style: d['style'] as String? ?? '',
        chars: (d['chars'] as num?)?.toInt() ?? 0,
        cached: d['cached'] == true,
        storageFileId: d['storageFileId'] as String?,
      ),
      failure: null,
    );
  }

  @visibleForTesting
  static Map<String, dynamic>? unwrapExecutionForTest(String body) =>
      _unwrapExecution(body);
}

Map<String, dynamic>? _unwrapExecution(String body) {
  try {
    final raw = jsonDecode(body);
    if (raw is! Map<String, dynamic>) return null;
    if (raw.containsKey('responseBody') && raw.containsKey('status')) {
      final inner = raw['responseBody'];
      if (inner is String && inner.isNotEmpty) {
        try {
          final innerJson = jsonDecode(inner);
          if (innerJson is Map<String, dynamic>) return innerJson;
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    return raw;
  } catch (_) {
    return null;
  }
}

final santaliTtsServiceProvider = Provider((ref) {
  final auth = ref.watch(appwriteAuthServiceProvider);
  return SantaliTtsService(functions: Functions(auth.client));
});
