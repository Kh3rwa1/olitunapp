import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/authorized_media.dart';
import '../media/authorized_media_provider.dart';
import 'private_audio_playback.dart';
import 'audio_service_stub.dart'
    if (dart.library.js_interop) 'audio_service_web.dart';

final audioServiceProvider = Provider((ref) {
  final service = AudioService(
    mediaService: ref.watch(authorizedMediaServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  late final PrivateAudioPlayback? _privatePlayback;

  /// URL most recently loaded into the shared player via [tryPlayUrl] or
  /// [playAsset], or null after [stop]/[dispose].
  ///
  /// Co-tenants of the single global player (Bakhed audio, lock SFX) use
  /// this to tell whether the player still carries *their* clip or has
  /// been hijacked by another surface, instead of each owning a private
  /// just_audio player (which wedges the shared audio_service session —
  /// a paused Bakhed session blocks sentence audio entirely).
  String? _currentUrl;
  String? get currentUrl => _currentUrl;

  /// Grace period after a clip finishes before the media session is
  /// released. Must comfortably exceed the playback controller's
  /// interClipPause (700ms) so bilingual chains are untouched.
  @visibleForTesting
  static Duration mediaSessionReleaseDelay = const Duration(seconds: 2);

  StreamSubscription<ProcessingState>? _sessionReleaseSub;

  /// Latest processing state observed from the shared player. The central
  /// controller reads this synchronously to detect a clip that finished
  /// while it was still awaiting startup (very short clips) — just_audio
  /// will not emit that completion a second time.
  ProcessingState _latestProcessingState = ProcessingState.idle;
  ProcessingState get currentProcessingState => _latestProcessingState;

  /// Fires when the web fallback element finishes a clip. just_audio
  /// never sees that element, so the central controller listens here
  /// to learn about completions on the fallback path.
  final StreamController<void> _webEndedController =
      StreamController<void>.broadcast();
  Stream<void> get webPlaybackEndedStream => _webEndedController.stream;

  AudioService({AuthorizedMediaService? mediaService}) {
    _privatePlayback = mediaService == null
        ? null
        : PrivateAudioPlayback(_player, mediaService);
    _initWebCrossOrigin();
    _initMediaSessionRelease();
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

  /// Dismisses the Android media notification shortly after a clip ends.
  ///
  /// just_audio_background keeps the media session alive for as long as a
  /// source is loaded — a 5-second pronunciation clip otherwise left a
  /// stuck "Pronunciation" notification in the shade indefinitely. When the
  /// player stops, it broadcasts processingState=idle, which makes
  /// audio_service remove the notification.
  ///
  /// The delay + state guard keeps bilingual sequencing (which auto-advances
  /// ~700ms after completion) and fresh play requests untouched.
  void _initMediaSessionRelease() {
    _sessionReleaseSub = _player.processingStateStream.listen((state) {
      _latestProcessingState = state;
      if (state != ProcessingState.completed) return;
      unawaited(_releaseMediaSession());
    });
  }

  Future<void> _releaseMediaSession() async {
    await Future<void>.delayed(mediaSessionReleaseDelay);
    // A follow-up clip (bilingual chain) or a new play request may have
    // started during the grace period — leave those alone.
    if (_player.processingState != ProcessingState.completed) return;
    try {
      _privatePlayback?.cancel();
      await _player.stop();
      AppLogger.debug('AudioService: media session released after completion');
    } catch (_) {
      AppLogger.warning('AudioService: media session release failed');
    }
  }

  /// Single source of truth for "is audio currently playing".
  ///
  /// Emits false on pause, stop, natural completion AND playback failure —
  /// consumers should derive UI state from this instead of local booleans,
  /// which silently desync.
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

  /// Full player state (playing flag + processing state) for co-tenants
  /// of the shared player (Bakhed) that mirror playback UI.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Attempts to play [url] and reports whether playback actually started.
  ///
  /// Unlike [playUrl], this surfaces success/failure so the central
  /// playback controller can show an error state (spec §11) instead of
  /// silently swallowing failures.
  ///
  /// [title]/[album]/[artUri] customize the background media notification;
  /// they default to the pronunciation values so existing call sites are
  /// unaffected. Co-tenants (Bakhed) pass their own metadata instead of
  /// spinning up a second player.
  Future<bool> tryPlayUrl(
    String url, {
    String title = 'Pronunciation',
    String album = 'Olitun',
    Uri? artUri,
  }) async {
    if (url.isEmpty) return false;
    if (PrivateMediaReference.parse(url) != null) {
      _initWebCrossOrigin();
      final started = await _privatePlayback?.play(url) ?? false;
      if (started) _currentUrl = url;
      return started;
    }
    _privatePlayback?.cancel();
    try {
      _initWebCrossOrigin();
      if (_player.playing) {
        await _player.pause();
      }
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(id: url, album: album, title: title, artUri: artUri),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play();
      _currentUrl = url;
      return true;
    } catch (e) {
      AppLogger.warning('AudioService playUrl failed: $e');
      if (kIsWeb) {
        try {
          _currentUrl = url;
          playNativeWebAudio(
            url,
            onEnded: () {
              if (!_webEndedController.isClosed) {
                _webEndedController.add(null);
              }
            },
          );
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
          _currentUrl = url;
          return true;
        } catch (retryErr) {
          AppLogger.warning('AudioService native retry failed: $retryErr');
          return false;
        }
      }
    }
  }

  /// Plays a bundled asset (error SFX, onboarding chimes) through the
  /// SHARED player so lightweight sounds can never wedge the global
  /// audio session the way a per-tap `AudioPlayer()` does (its dispose
  /// tears down the audio_service session out from under lesson audio).
  ///
  /// Fire-and-forget by design: returns false instead of throwing, so
  /// tests, offline, and silent devices stay quiet instead of crashing.
  Future<bool> playAsset(
    String assetPath, {
    String title = 'Olitun sound',
    String album = 'Olitun',
  }) async {
    if (assetPath.isEmpty) return false;
    _privatePlayback?.cancel();
    try {
      if (_player.playing) {
        await _player.pause();
      }
      await _player.setAudioSource(
        AudioSource.asset(
          assetPath,
          tag: MediaItem(id: assetPath, album: album, title: title),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play();
      _currentUrl = assetPath;
      return true;
    } catch (e) {
      AppLogger.warning('AudioService playAsset failed: $e');
      return false;
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
    } catch (_) {
      AppLogger.warning('AudioService pause failed');
    }
  }

  /// Resumes paused playback. Does nothing when nothing is loaded.
  Future<void> resume() async {
    if (_privatePlayback?.active ?? false) {
      await _privatePlayback!.resume();
      return;
    }
    try {
      await _player.play();
    } catch (_) {
      AppLogger.warning('AudioService resume failed');
    }
  }

  /// Seeks within the loaded source (spec §11: seek where relevant).
  Future<void> seek(Duration position) async {
    if (_privatePlayback?.active ?? false) {
      await _privatePlayback!.seek(position);
      return;
    }
    try {
      await _player.seek(position);
    } catch (_) {
      AppLogger.warning('AudioService seek failed');
    }
  }

  /// Sets the playback speed (spec §11: playback speed).
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (_) {
      AppLogger.warning('AudioService setSpeed failed');
    }
  }

  Future<void> stop() async {
    _currentUrl = null;
    _privatePlayback?.cancel();
    try {
      await _player.stop();
    } catch (_) {
      AppLogger.warning('AudioService: stop failed');
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
    _privatePlayback?.cancel();
    unawaited(_sessionReleaseSub?.cancel());
    unawaited(_webEndedController.close());
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
