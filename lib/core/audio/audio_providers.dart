import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

/// True while ANY audio (affirmation, letter, glyph...) is playing.
///
/// Global by design: there is exactly one [AudioPlayer], so playback state
/// is app-wide truth, not per-widget local state.
final audioIsPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioServiceProvider).isPlayingStream;
});
