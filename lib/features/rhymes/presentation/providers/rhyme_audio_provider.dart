import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/api/appwrite_functions_service.dart';
import '../../../home/presentation/providers/mission_providers.dart';
import 'listened_bakhed_provider.dart';
import 'notification_artwork_uri.dart';

class RhymeAudioState {
  final String? playingRhymeId;
  final bool isPlaying;
  final ProcessingState processingState;
  final Duration position;
  final Duration duration;
  final double speed;

  const RhymeAudioState({
    this.playingRhymeId,
    this.isPlaying = false,
    this.processingState = ProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  RhymeAudioState copyWith({
    String? playingRhymeId,
    bool? isPlaying,
    bool clearPlayingRhymeId = false,
    ProcessingState? processingState,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return RhymeAudioState(
      playingRhymeId: clearPlayingRhymeId
          ? null
          : (playingRhymeId ?? this.playingRhymeId),
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }
}

/// Bakhed audio state, driven by the SINGLE shared [AudioService] player.
///
/// A private just_audio player here wedges the shared audio_service session:
/// its paused/completed Bakhed item stays "current", after which sentence,
/// vocabulary and SFX playback through [AudioService] silently no-op.
/// Routing everything through the one global player enforces the
/// one-global-player rule (starting a clip always interrupts the previous
/// one) and lets the media notification follow whichever clip is live.
class RhymeAudioNotifier extends Notifier<RhymeAudioState> {
  late AudioService _audio;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _disposed = false;
  bool _eventTriggeredForCurrent = false;
  int _lastSyncedProgressPercent = -1;

  /// URL this notifier last started (null when idle or hijacked).
  String? _currentUrl;

  /// True while our own load is in flight (the shared service still
  /// reports the previous URL until our source finishes loading).
  bool _loading = false;

  @override
  RhymeAudioState build() {
    _audio = ref.watch(audioServiceProvider);
    _disposed = false;
    _eventTriggeredForCurrent = false;
    _lastSyncedProgressPercent = -1;
    _wirePlayerListeners();
    ref.onDispose(_cancelSubscriptions);
    return const RhymeAudioState();
  }

  /// True when the shared player still carries the clip this notifier
  /// started (i.e. no lesson/SFX surface has hijacked it since).
  bool get _ownsPlayer =>
      _currentUrl != null &&
      (_loading || _audio.currentUrl == _currentUrl);

  void _wirePlayerListeners() {
    _playerStateSub = _audio.playerStateStream.listen(
      (playerState) {
        if (_disposed) return;

        // A foreign clip (lesson audio, SFX) finished or is playing:
        // drop stale Bakhed state instead of reacting to it.
        if (!_ownsPlayer) {
          if (state.playingRhymeId != null || state.isPlaying) {
            state = state.copyWith(
              isPlaying: false,
              clearPlayingRhymeId: true,
              processingState: ProcessingState.idle,
              position: Duration.zero,
            );
          }
          return;
        }

        if (playerState.processingState == ProcessingState.completed) {
          // Our clip ended: relinquish ownership so the service release
          // timer can dismiss the notification, and re-arm our flags.
          _loading = false;
          _currentUrl = null;
          state = state.copyWith(
            isPlaying: false,
            clearPlayingRhymeId: true,
            processingState: ProcessingState.completed,
            position: Duration.zero,
          );
          return;
        }

        state = state.copyWith(
          isPlaying: playerState.playing,
          processingState: playerState.processingState,
        );
      },
      onError: (Object e) {
        AppLogger.debug('RhymeAudio: Player stream error: $e');
        _reset();
      },
    );

    _positionSub = _audio.positionStream.listen((pos) {
      if (_disposed || !_ownsPlayer) return;
      state = state.copyWith(position: pos);
      _checkBakhedCompletion();
    });

    _durationSub = _audio.durationStream.listen((dur) {
      if (_disposed || !_ownsPlayer) return;
      state = state.copyWith(duration: dur ?? Duration.zero);
      _checkBakhedCompletion();
    });
  }

  void _reset() {
    _currentUrl = null;
    _loading = false;
    _eventTriggeredForCurrent = false;
    _lastSyncedProgressPercent = -1;
    if (_disposed) return;
    state = const RhymeAudioState();
  }

  void _checkBakhedCompletion() {
    final pos = state.position;
    final dur = state.duration;
    final rhymeId = state.playingRhymeId;
    if (dur > Duration.zero && pos > Duration.zero && rhymeId != null) {
      final percentage = pos.inMilliseconds / dur.inMilliseconds;
      final percent = (percentage * 100).round().clamp(0, 100);
      final shouldSyncProgress =
          percent >= _lastSyncedProgressPercent + 10 ||
          (percent >= 80 && _lastSyncedProgressPercent < 80);
      if (shouldSyncProgress) {
        _lastSyncedProgressPercent = percent;
        unawaited(
          _recordBakhedProgress(
            bakhedId: rhymeId,
            listenedPercent: percent,
            lastPositionMs: pos.inMilliseconds,
          ),
        );
      }
      if (percentage >= 0.8 && !_eventTriggeredForCurrent) {
        _eventTriggeredForCurrent = true;
        ref.read(bakhedListenedTodayProvider.notifier).setCompleted(true);
        // Local "heard" badge for catalogue cards.
        ref.read(listenedBakhedProvider.notifier).markListened(rhymeId);
      }
    }
  }

  Future<void> togglePlay(
    String rhymeId,
    String? url, {
    String? title,
    String? artworkUrl,
  }) async {
    if (url == null || url.trim().isEmpty) {
      AppLogger.debug('RhymeAudio: No URL provided for $rhymeId');
      return;
    }

    // Resume/pause when our clip is still loaded in the shared player.
    if (state.playingRhymeId == rhymeId &&
        _ownsPlayer &&
        state.processingState != ProcessingState.idle &&
        state.processingState != ProcessingState.completed) {
      if (state.isPlaying) {
        await _audio.pause();
        state = state.copyWith(isPlaying: false);
      } else {
        await _audio.resume();
        state = state.copyWith(isPlaying: true);
      }
      return;
    }

    try {
      // One global player: Bakhed interrupts lesson audio and vice versa.
      await _audio.stop();
      _eventTriggeredForCurrent = false;
      _lastSyncedProgressPercent = -1;
      _currentUrl = url.trim();
      _loading = true;

      state = state.copyWith(
        playingRhymeId: rhymeId,
        isPlaying: false,
        processingState: ProcessingState.loading,
        position: Duration.zero,
        duration: Duration.zero,
      );

      final started = await _audio.tryPlayUrl(
        _currentUrl!,
        title: _notificationTitle(title),
        album: 'Olitun Bakhed',
        artUri: notificationArtworkUri(artworkUrl),
      );
      _loading = false;
      if (_disposed) return;
      if (!started || !_ownsPlayer) {
        AppLogger.debug('RhymeAudio: Error playing $url');
        await _audio.stop();
        _reset();
        return;
      }

      if (state.speed != 1.0) {
        await _audio.setSpeed(state.speed);
      }
      state = state.copyWith(
        isPlaying: true,
        processingState: ProcessingState.ready,
      );
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error playing $url: $e');
      await _audio.stop();
      _reset();
    }
  }

  Future<void> seek(Duration position) async {
    if (!_ownsPlayer) return;
    try {
      await _audio.seek(position);
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error seeking: $e');
    }
  }

  Future<void> stop() async {
    final owned = _ownsPlayer;
    _reset();
    if (owned) {
      try {
        await _audio.stop();
      } catch (e) {
        AppLogger.debug('RhymeAudio: Error stopping player: $e');
      }
    }
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    if (!_ownsPlayer) return;
    try {
      await _audio.setSpeed(speed);
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error setting speed: $e');
    }
  }

  String _notificationTitle(String? title) {
    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Bakhed';
    return trimmed;
  }

  Future<void> _recordBakhedProgress({
    required String bakhedId,
    required int listenedPercent,
    required int lastPositionMs,
  }) async {
    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      await functions.execute(
        'recordBakhedProgress',
        body: {
          'bakhedId': bakhedId,
          'listenedPercent': listenedPercent,
          'lastPositionMs': lastPositionMs,
        },
      );
    } catch (e) {
      AppLogger.debug('RhymeAudio: progress sync skipped: $e');
    }
  }

  void _cancelSubscriptions() {
    unawaited(_playerStateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    _playerStateSub = null;
    _positionSub = null;
    _durationSub = null;
  }

  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    // The shared AudioService player is app-scoped: never dispose it here.
  }
}

final rhymeAudioProvider =
    NotifierProvider<RhymeAudioNotifier, RhymeAudioState>(
      RhymeAudioNotifier.new,
    );
