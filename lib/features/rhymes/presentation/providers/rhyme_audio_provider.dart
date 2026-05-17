import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RhymeAudioState {
  final String? playingRhymeId;
  final bool isPlaying;
  final ProcessingState processingState;

  const RhymeAudioState({
    this.playingRhymeId,
    this.isPlaying = false,
    this.processingState = ProcessingState.idle,
  });

  RhymeAudioState copyWith({
    String? playingRhymeId,
    bool? isPlaying,
    ProcessingState? processingState,
  }) {
    return RhymeAudioState(
      playingRhymeId: playingRhymeId ?? this.playingRhymeId,
      isPlaying: isPlaying ?? this.isPlaying,
      processingState: processingState ?? this.processingState,
    );
  }
}

class RhymeAudioNotifier extends StateNotifier<RhymeAudioState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  RhymeAudioNotifier() : super(const RhymeAudioState()) {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (!mounted) return;

      if (playerState.processingState == ProcessingState.completed) {
        state = const RhymeAudioState(
          processingState: ProcessingState.completed,
        );
        unawaited(_player.pause());
        unawaited(_player.seek(Duration.zero));
        return;
      }

      state = state.copyWith(
        isPlaying: playerState.playing,
        processingState: playerState.processingState,
      );
    });
  }

  Future<void> togglePlay(
    String rhymeId,
    String? url, {
    String? title,
    String? artworkUrl,
  }) async {
    if (url == null || url.trim().isEmpty) {
      debugPrint('RhymeAudio: No URL provided for $rhymeId');
      return;
    }

    if (state.playingRhymeId == rhymeId) {
      if (state.isPlaying) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
      return;
    }

    try {
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: rhymeId,
            album: 'Olitun Bakhed',
            title: _notificationTitle(title),
            artUri: _safeUri(artworkUrl),
          ),
        ),
      );
      state = state.copyWith(playingRhymeId: rhymeId, isPlaying: true);
      unawaited(_player.play());
    } catch (e) {
      debugPrint('RhymeAudio: Error playing $url: $e');
      state = const RhymeAudioState();
    }
  }

  Future<void> stop() async {
    await _player.stop();
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
    unawaited(_player.dispose());
    super.dispose();
  }
}

final rhymeAudioProvider =
    StateNotifierProvider<RhymeAudioNotifier, RhymeAudioState>((ref) {
      return RhymeAudioNotifier();
    });
