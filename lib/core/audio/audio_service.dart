import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service_stub.dart'
    if (dart.library.js_interop) 'audio_service_web.dart';

final audioServiceProvider = Provider((ref) => AudioService());

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioService() {
    _initWebCrossOrigin();
  }

  void _initWebCrossOrigin() {
    if (kIsWeb) {
      try {
        _player.setWebCrossOrigin(WebCrossOrigin.anonymous);
      } catch (_) {}
    }
  }

  /// Single source of truth for "is audio currently playing".
  ///
  /// Emits false on pause, stop, natural completion AND playback failure —
  /// consumers should derive UI state from this instead of local booleans,
  /// which silently desync (the affirmation-card bug class).
  Stream<bool> get isPlayingStream =>
      _player.playerStateStream.map((state) => state.playing);

  Future<void> playUrl(String url) async {
    if (url.isEmpty) return;
    try {
      _initWebCrossOrigin();
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      AppLogger.warning('AudioService playUrl failed: $e');
      if (kIsWeb) {
        try {
          playNativeWebAudio(url);
        } catch (webErr) {
          AppLogger.warning('AudioService web fallback failed: $webErr');
        }
      }
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (kIsWeb) {
      try {
        stopNativeWebAudio();
      } catch (_) {}
    }
  }

  void dispose() {
    if (kIsWeb) {
      try {
        stopNativeWebAudio();
      } catch (_) {}
    }
    _player.dispose();
  }
}
