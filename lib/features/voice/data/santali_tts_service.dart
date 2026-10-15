import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/logging/app_logger.dart';

import 'bodhan_voice_catalog.dart';

/// Santali voice (Bodhan indic-speak) configuration.
///
/// The Bodhan API keys never live in the app: the Cloudflare Worker holds
/// them as secrets and rotates across accounts when one runs out of credit.
class SantaliVoiceConfig {
  /// Max characters per generation (matches the Worker's cap and keeps
  /// each request inside Bodhan's ~30s audio guidance).
  static const int maxChars = 600;
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

/// Talks to the Cloudflare Worker's `/voice/synthesize` route, signed with
/// the user's session JWT.
class SantaliTtsService {
  SantaliTtsService({http.Client? client, this.edgeAuth})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Signs Worker requests; the edge rejects anonymous calls.
  final EdgeAuth? edgeAuth;

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
    try {
      final authHeaders = await edgeAuth?.headers() ?? const {};
      final res = await _client
          .post(
            Uri.parse(CloudflareConfig.voiceSynthesizeEndpoint),
            headers: {'Content-Type': 'application/json', ...authHeaders},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200 && res.statusCode != 201) {
        final parsed = _decodeObject(res.body);
        final message = parsed?['message'];
        if (res.statusCode != 401 && message is String && message.isNotEmpty) {
          return (clip: null, failure: VoiceFailure(message));
        }
        return (clip: null, failure: _httpFailure(res.statusCode));
      }
      return _parsePayload(res.body);
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

  ({VoiceClip? clip, VoiceFailure? failure}) _parsePayload(String raw) {
    final parsed = _decodeObject(raw);
    if (parsed == null) {
      return (
        clip: null,
        failure: const VoiceFailure('Unexpected voice response. Try again.'),
      );
    }
    final d = parsed['data'] is Map ? (parsed['data'] as Map) : parsed;
    final audioUrl = d['audioUrl'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      final code = parsed['error'] as String?;
      final message =
          parsed['message'] as String? ?? 'Voice generation failed.';
      if (code == 'LOGIN_REQUIRED') {
        return (
          clip: null,
          failure: VoiceFailure(message, loginRequired: true),
        );
      }
      return (clip: null, failure: VoiceFailure(message));
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
  ({VoiceClip? clip, VoiceFailure? failure}) parsePayloadForTest(String raw) =>
      _parsePayload(raw);
}

Map<String, dynamic>? _decodeObject(String body) {
  try {
    final raw = jsonDecode(body);
    return raw is Map<String, dynamic> ? raw : null;
  } catch (_) {
    return null;
  }
}

final santaliTtsServiceProvider = Provider(
  (ref) => SantaliTtsService(edgeAuth: EdgeAuth.instance),
);
