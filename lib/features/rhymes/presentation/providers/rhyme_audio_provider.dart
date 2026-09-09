import 'package:itun/core/logging/app_logger.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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
    ProcessingState? processingState,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return RhymeAudioState(
      playingRhymeId: playingRhymeId ?? this.playingRhymeId,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }
}

class RhymeAudioNotifier extends Notifier<RhymeAudioState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _disposed = false;
  bool _eventTriggeredForCurrent = false;
  int _lastSyncedProgressPercent = -1;

  @override
  RhymeAudioState build() {
    _disposed = false;
    _eventTriggeredForCurrent = false;
    _lastSyncedProgressPercent = -1;
    _wirePlayerListeners();
    return const RhymeAudioState();
  }

  void _wirePlayerListeners() {
    _player.setWebCrossOrigin(WebCrossOrigin.anonymous);
    _playerStateSub = _player.playerStateStream.listen(
      (playerState) {
        if (_disposed) return;

        if (playerState.processingState == ProcessingState.completed) {
          state = state.copyWith(
            isPlaying: false,
            processingState: ProcessingState.completed,
            position: Duration.zero,
          );
          unawaited(_player.pause());
          unawaited(_player.seek(Duration.zero));
          return;
        }

        state = state.copyWith(
          isPlaying: playerState.playing,
          processingState: playerState.processingState,
        );
      },
      onError: (Object e) {
        AppLogger.debug('RhymeAudio: Player stream error: $e');
        state = const RhymeAudioState();
        unawaited(_player.stop());
      },
    );

    _positionSub = _player.positionStream.listen((pos) {
      if (_disposed) return;
      state = state.copyWith(position: pos);
      _checkBakhedCompletion();
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (_disposed) return;
      state = state.copyWith(duration: dur ?? Duration.zero);
      _checkBakhedCompletion();
    });
    ref.onDispose(dispose);
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

    if (state.playingRhymeId == rhymeId &&
        _player.audioSource != null &&
        _player.processingState != ProcessingState.idle) {
      if (state.isPlaying) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
      return;
    }

    try {
      await _player.stop();
      _eventTriggeredForCurrent = false;
      _lastSyncedProgressPercent = -1;
      await _player
          .setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: rhymeId,
                album: 'Olitun Bakhed',
                title: _notificationTitle(title),
                artUri: notificationArtworkUri(artworkUrl),
              ),
            ),
          )
          .timeout(const Duration(seconds: 12));

      final resolvedDuration = _player.duration ?? state.duration;
      state = state.copyWith(
        playingRhymeId: rhymeId,
        isPlaying: true,
        duration: resolvedDuration,
        processingState: _player.processingState,
      );
      unawaited(_player.play());
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error playing $url: $e');
      state = const RhymeAudioState();
      unawaited(_player.stop());
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error seeking: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      AppLogger.debug('RhymeAudio: Error stopping player: $e');
    }
    state = const RhymeAudioState();
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      state = state.copyWith(speed: speed);
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

  void dispose() {
    _disposed = true;
    unawaited(_playerStateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_player.dispose());
  }
}

final rhymeAudioProvider =
    NotifierProvider<RhymeAudioNotifier, RhymeAudioState>(
      RhymeAudioNotifier.new,
    );
