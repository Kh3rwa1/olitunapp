import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class RhymeAudioState {
  final String? playingRhymeId;
  final bool isPlaying;
  final PlayerState playerState;

  RhymeAudioState({
    this.playingRhymeId,
    this.isPlaying = false,
    this.playerState = PlayerState.stopped,
  });

  RhymeAudioState copyWith({
    String? playingRhymeId,
    bool? isPlaying,
    PlayerState? playerState,
  }) {
    return RhymeAudioState(
      playingRhymeId: playingRhymeId ?? this.playingRhymeId,
      isPlaying: isPlaying ?? this.isPlaying,
      playerState: playerState ?? this.playerState,
    );
  }
}

class RhymeAudioNotifier extends StateNotifier<RhymeAudioState> {
  final AudioPlayer _player = AudioPlayer();

  RhymeAudioNotifier() : super(RhymeAudioState()) {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        this.state = this.state.copyWith(
          playerState: state,
          isPlaying: state == PlayerState.playing,
        );
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        state = RhymeAudioState(playerState: PlayerState.completed);
      }
    });
  }

  Future<void> togglePlay(String rhymeId, String? url) async {
    if (url == null || url.isEmpty) {
      debugPrint('RhymeAudio: No URL provided for $rhymeId');
      return;
    }

    if (state.playingRhymeId == rhymeId) {
      if (state.isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } else {
      await _player.stop();
      try {
        await _player.play(UrlSource(url));
        state = state.copyWith(playingRhymeId: rhymeId, isPlaying: true);
      } catch (e) {
        debugPrint('RhymeAudio: Error playing $url: $e');
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = RhymeAudioState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final rhymeAudioProvider =
    StateNotifierProvider<RhymeAudioNotifier, RhymeAudioState>((ref) {
      return RhymeAudioNotifier();
    });
