import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';
import 'playback_controller.dart';

/// The single central playback controller for the whole app.
///
/// Tests override this provider with a controller built on a mocked
/// [AudioService] — the controller itself never touches Appwrite.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(
    audioService: ref.watch(audioServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Broadcast playback state for reactive listeners.
///
/// The stream emits the current [PlaybackState] on every change. It is
/// seeded with `controller.state` when first watched because the
/// controller is constructed before the first stream event; consumers
/// that need an initial value immediately should read
/// `ref.watch(playbackControllerProvider).state` as the fallback (see
/// [AudioControlsBar] which instead uses the manual listener pattern to
/// avoid rebuilding on every position tick).
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.stateStream;
});
