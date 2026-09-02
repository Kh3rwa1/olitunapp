import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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
      } catch (e) {
        AppLogger.warning('AudioService: failed to set web cross-origin: $e');
      }
    }
  }

  /// Single source of truth for "is audio currently playing".
  ///
  /// Emits false on pause, stop, natural completion AND playback failure —
  /// consumers should derive UI state from this instead of local booleans,
  /// which silently desync (the affirmation-card bug class).
  Stream<bool> get isPlayingStream =>
      _player.playerStateStream.map((state) => state.playing);

  /// Playback position, for progress display in the central controller.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total duration of the loaded source, once known.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// just_audio processing state, for completion/error detection in the
  /// central playback controller (bilingual sequencing).
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  /// Attempts to play [url] and reports whether playback actually started.
  ///
  /// Unlike [playUrl], this surfaces success/failure so the central
  /// playback controller can show an error state (spec §11) instead of
  /// silently swallowing failures.
  Future<bool> tryPlayUrl(String url) async {
    if (url.isEmpty) return false;
    try {
      _initWebCrossOrigin();
      if (_player.playing) {
        await _player.pause();
      }
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(id: url, album: 'Olitun', title: 'Pronunciation'),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play();
      return true;
    } catch (e) {
      AppLogger.warning('AudioService playUrl failed: $e');
      if (kIsWeb) {
        try {
          playNativeWebAudio(url);
          return true;
        } catch (webErr) {
          AppLogger.warning('AudioService web fallback failed: $webErr');
          return false;
        }
      } else {
        try {
          await _player.setUrl(url);
          await _player.setVolume(1.0);
          await _player.play();
          return true;
        } catch (retryErr) {
          AppLogger.warning('AudioService native retry failed: $retryErr');
          return false;
        }
      }
    }
  }

  /// Fire-and-forget playback used by lightweight call sites (glyph cards,
  /// legacy buttons). The central [PlaybackController] uses [tryPlayUrl]
  /// instead so it can track loading/error state.
  Future<void> playUrl(String url) async {
    await tryPlayUrl(url);
  }

  /// Pauses the current playback without unloading it.
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      AppLogger.warning('AudioService pause failed: $e');
    }
  }

  /// Resumes paused playback. Does nothing when nothing is loaded.
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      AppLogger.warning('AudioService resume failed: $e');
    }
  }

  /// Seeks within the loaded source (spec §11: seek where relevant).
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      AppLogger.warning('AudioService seek failed: $e');
    }
  }

  /// Sets the playback speed (spec §11: playback speed).
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      AppLogger.warning('AudioService setSpeed failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      AppLogger.warning('AudioService: stop failed: $e');
    }
    if (kIsWeb) {
      try {
        stopNativeWebAudio();
      } catch (e) {
        AppLogger.warning('AudioService: native web stop failed: $e');
      }
    }
  }

  void dispose() {
    if (kIsWeb) {
      try {
        stopNativeWebAudio();
      } catch (e) {
        AppLogger.warning('AudioService: native web stop failed: $e');
      }
    }
    _player.dispose();
  }
}
