import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:itun/core/audio/audio_service.dart';

/// Records loads and lets tests drive processing-state transitions through
/// the platform event stream (the interface has no platform-level stop —
/// just_audio's stop() deactivates the platform player Dart-side and
/// broadcasts processingState=idle, which is exactly what makes
/// audio_service remove the Android media notification).
class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform({required String id, this.onLoadDuration})
    : super(id);

  final Duration? onLoadDuration;
  final _events = StreamController<PlaybackEventMessage>.broadcast();
  int loadCount = 0;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  void emitState(ProcessingStateMessage state) {
    _events.add(
      PlaybackEventMessage(
        processingState: state,
        updatePosition: Duration.zero,
        updateTime: DateTime.now(),
        bufferedPosition: Duration.zero,
        icyMetadata: null,
        duration: const Duration(seconds: 5),
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    loadCount++;
    emitState(ProcessingStateMessage.ready);
    return LoadResponse(duration: onLoadDuration ?? const Duration(seconds: 5));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async =>
      DisposeResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();
}

/// Platform-level fake: hands out the per-player fake and absorbs lifecycle
/// calls (mirrors test/core/storage/media_uploader_duration_test.dart).
class FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return fakePlayer;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async => DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

late FakeAudioPlayerPlatform fakePlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    fakePlayer = FakeAudioPlayerPlatform(id: 'test-player');
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    // Shrink the grace period so tests stay fast.
    AudioService.mediaSessionReleaseDelay = const Duration(milliseconds: 120);
  });

  tearDown(() {
    AudioService.mediaSessionReleaseDelay = const Duration(seconds: 2);
  });

  test('releases the media session (idle) after a clip completes', () async {
    final service = AudioService();
    final states = <Object>[];
    final sub = service.processingStateStream.listen(states.add);

    await service.tryPlayUrl('https://example.com/clip.mp3');
    await Future<void>.delayed(Duration.zero);
    states.clear(); // drop the player's pre-load initial idle
    fakePlayer.emitState(ProcessingStateMessage.completed);

    // Within the grace period the session must NOT be released yet.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(states.any((s) => s.toString().contains('idle')), isFalse);

    // After the grace period the player is stopped -> processingState=idle
    // -> audio_service removes the media notification.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    expect(states.any((s) => s.toString().contains('idle')), isTrue);

    await sub.cancel();
  });

  test('does NOT release the session when a new clip starts during the '
      'grace window (bilingual sequencing)', () async {
    final service = AudioService();
    final states = <Object>[];
    final sub = service.processingStateStream.listen(states.add);

    await service.tryPlayUrl('https://example.com/clip.mp3');
    await Future<void>.delayed(Duration.zero);
    states.clear(); // drop the player's pre-load initial idle
    fakePlayer.emitState(ProcessingStateMessage.completed);

    // Follow-up clip starts before the grace period elapses.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await service.tryPlayUrl('https://example.com/next.mp3');
    fakePlayer.emitState(ProcessingStateMessage.ready);

    await Future<void>.delayed(const Duration(milliseconds: 220));

    // No idle (release) may have been broadcast: the new clip was
    // ready/loading when the grace timer checked.
    expect(states.any((s) => s.toString().contains('idle')), isFalse);

    await sub.cancel();
  });

  test('a pause (no completion) never triggers a release', () async {
    final service = AudioService();
    final states = <Object>[];
    final sub = service.processingStateStream.listen(states.add);

    await service.tryPlayUrl('https://example.com/clip.mp3');
    await Future<void>.delayed(Duration.zero);
    states.clear(); // drop the player's pre-load initial idle
    fakePlayer.emitState(ProcessingStateMessage.buffering);
    fakePlayer.emitState(ProcessingStateMessage.ready);

    await Future<void>.delayed(const Duration(milliseconds: 220));
    expect(states.any((s) => s.toString().contains('idle')), isFalse);

    await sub.cancel();
  });
}
