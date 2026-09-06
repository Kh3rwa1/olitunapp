import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../media/authorized_media.dart';

/// Shares AudioService's single player; never creates a second media session.
/// Bearer URLs live only in this lease/player, not in playback ids or metadata.
class PrivateAudioPlayback {
  PrivateAudioPlayback(this.player, this.media);

  final AudioPlayer player;
  final AuthorizedMediaService media;
  String? _source;
  Timer? _refresh;
  int _generation = 0;
  bool get active => _source != null;

  Future<bool> play(String source) async {
    cancel();
    _source = source;
    return _load(Duration.zero, true);
  }

  Future<bool> _load(Duration position, bool playing) async {
    final source = _source;
    if (source == null) return false;
    final generation = ++_generation;
    _refresh?.cancel();
    try {
      await player.pause();
      final lease = await media.resolve(source);
      if (generation != _generation) return false;
      await player.setAudioSource(
        AudioSource.uri(
          lease.uri,
          tag: MediaItem(id: source, album: 'Olitun', title: 'Lesson audio'),
        ),
        initialPosition: position,
      );
      if (generation != _generation) return false;
      final delay = lease.refreshAfter(media.clock());
      if (delay == null || delay <= Duration.zero) {
        throw const MediaAccessException();
      }
      _refresh = Timer(delay, () {
        if (generation == _generation) {
          unawaited(_load(player.position, player.playing));
        }
      });
      if (playing) {
        // play() completes at the END of the clip, not when playback starts.
        unawaited(player.play().catchError((Object _) async {
          if (generation == _generation) {
            cancel();
            await player.stop();
          }
        }));
      }
      return true;
    } catch (_) {
      // Never log player errors: they may contain a tokenized URI.
      if (generation == _generation) {
        cancel();
        await player.stop();
      }
      return false;
    }
  }

  Future<void> resume() async {
    await _load(player.position, true);
  }

  Future<void> seek(Duration position) async {
    // Seeking may initiate new range requests after a long pause. Obtain a
    // fresh, reauthorized lease rather than reusing an expired player URI.
    await _load(position, player.playing);
  }

  void cancel() {
    _generation++;
    _refresh?.cancel();
    _refresh = null;
    _source = null;
  }
}
