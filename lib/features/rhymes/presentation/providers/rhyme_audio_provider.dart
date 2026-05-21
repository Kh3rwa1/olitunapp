import 'package:itun/core/logging/app_logger.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../home/presentation/providers/mission_providers.dart';

class RhymeAudioState {
  final String? playingRhymeId;
  final bool isPlaying;
  final ProcessingState processingState;
  final Duration position;
  final Duration duration;

  const RhymeAudioState({
    this.playingRhymeId,
    this.isPlaying = false,
    this.processingState = ProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  RhymeAudioState copyWith({
    String? playingRhymeId,
    bool? isPlaying,
    ProcessingState? processingState,
    Duration? position,
    Duration? duration,
  }) {
    return RhymeAudioState(
      playingRhymeId: playingRhymeId ?? this.playingRhymeId,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class RhymeAudioNotifier extends StateNotifier<RhymeAudioState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  final Ref? _ref;

  RhymeAudioNotifier({Ref? ref}) : _ref = ref, super(const RhymeAudioState()) {
    _playerStateSub = _player.playerStateStream.listen(
      (playerState) {
        if (!mounted) return;

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
      if (!mounted) return;
      state = state.copyWith(position: pos);
      _checkBakhedCompletion();
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (!mounted) return;
      state = state.copyWith(duration: dur ?? Duration.zero);
      _checkBakhedCompletion();
    });
  }

  void _checkBakhedCompletion() {
    final pos = state.position;
    final dur = state.duration;
    if (dur > Duration.zero && pos > Duration.zero) {
      final percentage = pos.inMilliseconds / dur.inMilliseconds;
      if (percentage >= 0.8) {
        _ref?.read(bakhedListenedTodayProvider.notifier).setCompleted(true);
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
      await _player
          .setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: rhymeId,
                album: 'Olitun Bakhed',
                title: _notificationTitle(title),
                artUri: _safeUri(artworkUrl),
              ),
            ),
          )
          .timeout(const Duration(seconds: 12));

      state = state.copyWith(
        playingRhymeId: rhymeId,
        isPlaying: true,
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

  String _notificationTitle(String? title) {
    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Bakhed';
    return trimmed;
  }

  Uri? _safeUri(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return Uri.tryParse(trimmed);
  }

  @override
  void dispose() {
    unawaited(_playerStateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}

final rhymeAudioProvider =
    StateNotifierProvider<RhymeAudioNotifier, RhymeAudioState>((ref) {
      return RhymeAudioNotifier(ref: ref);
    });
