import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';

class MockAudioService extends Mock implements AudioService {}

PlaybackRequest request(
  String id, {
  PlaybackRequest? next,
  String trackType = 'targetNormal',
  String languageCode = 'sat',
}) {
  return PlaybackRequest(
    id: id,
    contentKind: 'word',
    contentId: 'w1',
    trackType: trackType,
    languageCode: languageCode,
    next: next,
  );
}

/// Lets pending microtasks (async play/advance continuations) run.
Future<void> flush([int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  late MockAudioService audio;
  late StreamController<ProcessingState> processingStates;
  late StreamController<Duration> positions;
  late StreamController<Duration?> durations;

  setUp(() {
    audio = MockAudioService();
    processingStates = StreamController<ProcessingState>.broadcast();
    positions = StreamController<Duration>.broadcast();
    durations = StreamController<Duration?>.broadcast();

    when(
      () => audio.processingStateStream,
    ).thenAnswer((_) => processingStates.stream);
    when(() => audio.positionStream).thenAnswer((_) => positions.stream);
    when(() => audio.durationStream).thenAnswer((_) => durations.stream);
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.pause()).thenAnswer((_) async {});
    when(() => audio.resume()).thenAnswer((_) async {});
    when(() => audio.seek(any())).thenAnswer((_) async {});
    when(() => audio.setSpeed(any())).thenAnswer((_) async {});
    when(() => audio.tryPlayUrl(any())).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await processingStates.close();
    await positions.close();
    await durations.close();
  });

  PlaybackController build({
    Duration pause = const Duration(milliseconds: 700),
  }) {
    final controller = PlaybackController(
      audioService: audio,
      interClipPause: pause,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  group('PlaybackRequest', () {
    test('chain links clips head-first and returns null when empty', () {
      final a = request('a.mp3');
      final b = request('b.mp3', trackType: 'explanation', languageCode: 'en');

      final head = PlaybackRequest.chain([a, b]);

      // withNext is an immutable copy, so the head is a linked copy of `a`.
      expect(head, isNotNull);
      expect(head!.id, a.id);
      expect(head.next, same(b));
      expect(head.next!.next, isNull);
      expect(PlaybackRequest.chain(const <PlaybackRequest>[]), isNull);
    });

    test('withNext returns a copy with the new link', () {
      final a = request('a.mp3');
      final b = request('b.mp3');

      final linked = a.withNext(b);

      expect(linked.id, a.id);
      expect(linked.next, same(b));
      expect(a.next, isNull, reason: 'original is immutable');
    });

    test('equality covers the five identity fields and ignores next', () {
      final a = request('a.mp3');
      final aLinked = a.withNext(request('b.mp3'));
      final same = request('a.mp3');
      final otherLanguage = request('a.mp3', languageCode: 'en');

      expect(a, aLinked);
      expect(a.hashCode, aLinked.hashCode);
      expect(a, same);
      expect(a, isNot(otherLanguage));
    });
  });

  group('PlaybackState', () {
    test('isIdle and isFor', () {
      const idle = PlaybackState();
      expect(idle.isIdle, isTrue);
      expect(idle.isFor('word', 'w1'), isFalse);

      const loaded = PlaybackState(
        current: PlaybackRequest(
          id: 'a.mp3',
          contentKind: 'word',
          contentId: 'w1',
          trackType: 'targetNormal',
          languageCode: 'sat',
        ),
      );
      expect(loaded.isIdle, isFalse);
      expect(loaded.isFor('word', 'w1'), isTrue);
      expect(loaded.isFor('word', 'other'), isFalse);
      expect(loaded.isFor('lesson', 'w1'), isFalse);
    });

    test('copyWith keeps unspecified fields and can clear error with null', () {
      const state = PlaybackState(
        isPlaying: true,
        error: 'Could not play audio',
        position: Duration(seconds: 3),
        speed: 1.25,
      );

      final kept = state.copyWith();
      expect(kept.isPlaying, isTrue);
      expect(kept.error, 'Could not play audio');
      expect(kept.position, const Duration(seconds: 3));
      expect(kept.speed, 1.25);

      final cleared = state.copyWith(error: null, isPlaying: false);
      expect(cleared.error, isNull);
      expect(cleared.isPlaying, isFalse);
      expect(cleared.speed, 1.25);
    });
  });

  group('play', () {
    test('stops the previous clip first, then starts the new one', () async {
      final controller = build();

      await controller.play(request('https://a.mp3'));

      verifyInOrder([
        () => audio.stop(),
        () => audio.tryPlayUrl('https://a.mp3'),
      ]);
      expect(controller.state.current?.id, 'https://a.mp3');
      expect(controller.state.rootRequest?.id, 'https://a.mp3');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isPlaying, isTrue);
      expect(controller.state.error, isNull);
    });

    test('does not re-apply the default 1.0 speed', () async {
      final controller = build();

      await controller.play(request('https://a.mp3'));

      verifyNever(() => audio.setSpeed(any()));
    });

    test('playSingle builds the request with full metadata', () async {
      final controller = build();

      await controller.playSingle(
        id: 'https://a.mp3',
        contentKind: 'letter',
        contentId: 'letter_1',
        trackType: 'targetNormal',
        languageCode: 'sat',
      );

      final current = controller.state.current;
      expect(current, isNotNull);
      expect(current!.id, 'https://a.mp3');
      expect(current.contentKind, 'letter');
      expect(current.contentId, 'letter_1');
      expect(current.trackType, 'targetNormal');
      expect(current.languageCode, 'sat');
      expect(current.next, isNull);
    });

    test('missing track (empty id) yields "Audio unavailable"', () async {
      final controller = build();

      await controller.play(request(''));

      expect(controller.state.error, 'Audio unavailable');
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isLoading, isFalse);
      verifyNever(() => audio.tryPlayUrl(any()));
    });

    test('failed start yields "Could not play audio"', () async {
      when(
        () => audio.tryPlayUrl('https://bad.mp3'),
      ).thenAnswer((_) async => false);
      final controller = build();

      await controller.play(request('https://bad.mp3'));

      expect(controller.state.error, 'Could not play audio');
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isLoading, isFalse);
    });

    test('a newer request supersedes an older one', () async {
      final controller = build();

      final first = controller.play(request('https://a.mp3'));
      final second = controller.play(request('https://b.mp3'));
      await first;
      await second;

      verifyNever(() => audio.tryPlayUrl('https://a.mp3'));
      verify(() => audio.tryPlayUrl('https://b.mp3')).called(1);
      expect(controller.state.current?.id, 'https://b.mp3');
      expect(controller.state.rootRequest?.id, 'https://b.mp3');
    });
  });

  group('chain advancement', () {
    test('completed clip advances to the next clip', () async {
      final controller = build(pause: Duration.zero);
      final head = request(
        'https://a.mp3',
        next: request(
          'https://b.mp3',
          trackType: 'explanation',
          languageCode: 'en',
        ),
      );

      await controller.play(head);
      verify(() => audio.tryPlayUrl('https://a.mp3')).called(1);

      processingStates.add(ProcessingState.completed);
      await flush();

      verify(() => audio.tryPlayUrl('https://b.mp3')).called(1);
      expect(controller.state.current?.id, 'https://b.mp3');
      expect(controller.state.isPlaying, isTrue);
      expect(controller.state.error, isNull);
    });

    test('waits for the inter-clip pause before the next clip', () async {
      final controller = build(pause: const Duration(milliseconds: 50));
      final head = request('https://a.mp3', next: request('https://b.mp3'));

      await controller.play(head);
      processingStates.add(ProcessingState.completed);
      await flush();

      verifyNever(() => audio.tryPlayUrl('https://b.mp3'));

      await Future<void>.delayed(const Duration(milliseconds: 120));
      verify(() => audio.tryPlayUrl('https://b.mp3')).called(1);
    });

    test('an unplayable follow-up clip is skipped gracefully', () async {
      final controller = build(pause: Duration.zero);
      final head = request('https://a.mp3', next: request(''));

      await controller.play(head);
      processingStates.add(ProcessingState.completed);
      await flush();

      expect(controller.state.error, 'Audio unavailable');
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isLoading, isFalse);
      verify(() => audio.tryPlayUrl('https://a.mp3')).called(1);
    });

    test('non-completed processing states are ignored', () async {
      final controller = build(pause: Duration.zero);
      final head = request('https://a.mp3', next: request('https://b.mp3'));

      await controller.play(head);

      processingStates.add(ProcessingState.ready);
      await flush();

      expect(controller.state.isPlaying, isTrue);
      verifyNever(() => audio.tryPlayUrl('https://b.mp3'));
    });

    test('chain end settles into a stopped-but-loaded state', () async {
      final controller = build(pause: Duration.zero);

      await controller.play(request('https://a.mp3'));
      processingStates.add(ProcessingState.completed);
      await flush();

      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.current?.id, 'https://a.mp3');
      expect(controller.playPauseSemanticsLabel, 'Resume audio');
    });
  });

  group('pause, resume and toggle', () {
    test('pause stops playback and resume restarts it', () async {
      final controller = build();
      await controller.play(request('https://a.mp3'));

      await controller.pause();
      expect(controller.state.isPlaying, isFalse);
      verify(() => audio.pause()).called(1);

      await controller.resume();
      expect(controller.state.isPlaying, isTrue);
      verify(() => audio.resume()).called(1);
    });

    test('togglePlayPause flips between pause and resume', () async {
      final controller = build();
      await controller.play(request('https://a.mp3'));

      await controller.togglePlayPause();
      expect(controller.state.isPlaying, isFalse);

      await controller.togglePlayPause();
      expect(controller.state.isPlaying, isTrue);
    });

    test('toggle and resume do nothing when idle', () async {
      final controller = build();

      await controller.togglePlayPause();
      await controller.resume();

      verifyNever(() => audio.pause());
      verifyNever(() => audio.resume());
      expect(controller.state.isIdle, isTrue);
    });
  });

  group('stop and replay', () {
    test('stop clears the loaded clip but keeps the speed setting', () async {
      final controller = build();
      await controller.play(request('https://a.mp3'));
      await controller.setSpeed(1.5);

      await controller.stop();

      expect(controller.state.isIdle, isTrue);
      expect(controller.state.isPlaying, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.speed, 1.5);
      // One stop from play() itself, one from the explicit stop().
      verify(() => audio.stop()).called(2);
    });

    test('replay plays the root request again', () async {
      final controller = build(pause: Duration.zero);
      final head = request(
        'https://a.mp3',
        next: request(
          'https://b.mp3',
          trackType: 'explanation',
          languageCode: 'en',
        ),
      );

      await controller.play(head);
      processingStates.add(ProcessingState.completed);
      await flush();
      verify(() => audio.tryPlayUrl('https://a.mp3')).called(1);
      verify(() => audio.tryPlayUrl('https://b.mp3')).called(1);

      await controller.replay();

      expect(controller.state.current?.id, 'https://a.mp3');
      expect(controller.state.rootRequest?.id, 'https://a.mp3');
      // mocktail consumes verified calls, so this counts only the replay call.
      verify(() => audio.tryPlayUrl('https://a.mp3')).called(1);
    });

    test('replay does nothing when idle', () async {
      final controller = build();

      await controller.replay();

      verifyNever(() => audio.tryPlayUrl(any()));
    });
  });

  group('seek', () {
    test('clamps to the loaded duration and to zero', () async {
      final controller = build();
      durations.add(const Duration(seconds: 10));
      await flush();
      expect(controller.state.duration, const Duration(seconds: 10));

      await controller.seek(const Duration(seconds: 20));
      verify(() => audio.seek(const Duration(seconds: 10)));
      expect(controller.state.position, const Duration(seconds: 10));

      await controller.seek(const Duration(seconds: 5));
      verify(() => audio.seek(const Duration(seconds: 5)));
      expect(controller.state.position, const Duration(seconds: 5));

      await controller.seek(const Duration(seconds: -3));
      verify(() => audio.seek(Duration.zero));
      expect(controller.state.position, Duration.zero);
    });

    test('passes through when the duration is unknown', () async {
      final controller = build();

      await controller.seek(const Duration(seconds: 5));

      verify(() => audio.seek(const Duration(seconds: 5)));
      expect(controller.state.position, const Duration(seconds: 5));
    });
  });

  group('setSpeed', () {
    test('clamps to the [0.5, 2.0] range', () async {
      final controller = build();

      await controller.setSpeed(0.3);
      expect(controller.state.speed, 0.5);
      verify(() => audio.setSpeed(0.5)).called(1);

      await controller.setSpeed(3.0);
      expect(controller.state.speed, 2.0);
      verify(() => audio.setSpeed(2.0)).called(1);

      await controller.setSpeed(0.75);
      expect(controller.state.speed, 0.75);
    });

    test('speed is re-applied to every new clip', () async {
      final controller = build();
      await controller.setSpeed(0.75);

      await controller.play(request('https://a.mp3'));

      verifyInOrder([
        () => audio.tryPlayUrl('https://a.mp3'),
        () => audio.setSpeed(0.75),
      ]);
      expect(controller.state.speed, 0.75);
    });
  });

  group('semantics labels', () {
    test('reflect idle, playing and paused states', () async {
      final controller = build();
      expect(controller.playPauseSemanticsLabel, 'Play audio');
      expect(
        controller.replaySemanticsLabel,
        'Replay audio from the beginning',
      );

      await controller.play(request('https://a.mp3'));
      expect(controller.playPauseSemanticsLabel, 'Pause audio');

      await controller.pause();
      expect(controller.playPauseSemanticsLabel, 'Resume audio');
    });
  });

  group('state plumbing', () {
    test('position stream updates the state position', () async {
      final controller = build();

      positions.add(const Duration(seconds: 3));
      await flush();

      expect(controller.state.position, const Duration(seconds: 3));
    });

    test('duration stream updates the state duration', () async {
      final controller = build();

      durations.add(const Duration(seconds: 12));
      await flush();
      expect(controller.state.duration, const Duration(seconds: 12));

      durations.add(null);
      await flush();
      expect(controller.state.duration, const Duration(seconds: 12));
    });

    test('manual listeners are notified and can be removed', () async {
      final controller = build();
      final seen = <PlaybackState>[];
      controller.addListener(seen.add);

      await controller.play(request('https://a.mp3'));
      expect(seen, isNotEmpty);

      controller.removeListener(seen.add);
      seen.clear();

      await controller.play(request('https://b.mp3'));
      expect(seen, isEmpty);
    });

    test('stateStream broadcasts every state change', () async {
      final controller = build();
      final events = <PlaybackState>[];
      final sub = controller.stateStream.listen(events.add);

      await controller.play(request('https://a.mp3'));
      await flush();

      expect(events, isNotEmpty);
      expect(events.last.isPlaying, isTrue);
      await sub.cancel();
    });
  });

  group('dispose', () {
    test('stops listening to the audio service streams', () async {
      final controller = build();
      await controller.play(request('https://a.mp3'));

      final events = <PlaybackState>[];
      final sub = controller.stateStream.listen(events.add);
      controller.dispose();
      await sub.cancel();
      events.clear();

      processingStates.add(ProcessingState.completed);
      await flush();

      expect(
        controller.state.isPlaying,
        isTrue,
        reason: 'cancelled subscription no longer advances the chain',
      );
      expect(events, isEmpty);
    });
  });
}
