import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'package:itun/core/logging/app_logger.dart';
import 'download_io.dart'
    if (dart.library.js_interop) 'download_web.dart'
    as platform;

/// Saves a generated voice clip onto the user's device.
///
/// - Mobile/desktop: downloads the WAV bytes and opens the system share
///   sheet so the learner can save it to Files/Downloads or send it to
///   friends (the viral loop). The file is also kept in the app documents
///   directory under `olitun_voice/`.
/// - Web: triggers a browser download (`olitun-voice-<ts>.wav`).
class VoiceDownloadService {
  VoiceDownloadService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Downloads [audioUrl] and hands it to the platform save flow.
  /// Returns a short human message for a snackbar, or null on failure
  /// (the caller then shows [errorMessage]).
  String? errorMessage;

  Future<String?> saveClip({
    required String audioUrl,
    required String voice,
  }) async {
    errorMessage = null;
    try {
      final response = await _client.get(Uri.parse(audioUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        errorMessage =
            'Download failed (HTTP ${response.statusCode}). Try again.';
        return null;
      }
      final bytes = response.bodyBytes;
      final fileName = _fileName(voice);
      final savedPath = await platform.saveVoiceBytes(fileName, bytes);
      if (!kIsWeb && savedPath != null) {
        // Open the share sheet so the clip can leave the app: save to
        // Files, WhatsApp it, post it — this is the viral loop.
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(savedPath, name: fileName, mimeType: 'audio/wav')],
            text: 'My Santali AI voice — made with Olitun',
          ),
        );
      }
      return kIsWeb ? 'Audio downloaded.' : 'Audio saved — share it anywhere.';
    } catch (e) {
      AppLogger.debug('VoiceDownloadService failed: $e');
      errorMessage = 'Could not save audio. Check storage and try again.';
      return null;
    }
  }

  String _fileName(String voice) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeVoice = voice.isEmpty
        ? 'santali'
        : voice.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return 'olitun-${safeVoice.isEmpty ? 'voice' : safeVoice}-$ts.wav';
  }
}

/// Visible for tests: deterministic file names without timestamps.
@visibleForTesting
String voiceFileNameForTest(String voice, int timestampMs) {
  final safeVoice = voice.isEmpty
      ? 'santali'
      : voice.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  return 'olitun-${safeVoice.isEmpty ? 'voice' : safeVoice}-$timestampMs.wav';
}
