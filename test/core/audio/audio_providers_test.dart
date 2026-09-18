import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_providers.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioService extends Mock implements AudioService {}

Future<void> flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late MockAudioService audioService;
  late StreamController<bool> playingController;
  late ProviderContainer container;

  setUp(() {
    audioService = MockAudioService();
    playingController = StreamController<bool>.broadcast();

    when(
      () => audioService.isPlayingStream,
    ).thenAnswer((_) => playingController.stream);

    container = ProviderContainer(
      overrides: [audioServiceProvider.overrideWithValue(audioService)],
    );
  });

  tearDown(() async {
    container.dispose();
    await playingController.close();
  });

  group('audioIsPlayingProvider', () {
    test('starts in loading state while waiting for the first value', () {
      final subscription = container.listen(
        audioIsPlayingProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(container.read(audioIsPlayingProvider), isA<AsyncLoading<bool>>());
    });

    test('forwards playing and stopped states from AudioService', () async {
      final states = <AsyncValue<bool>>[];

      final subscription = container.listen(
        audioIsPlayingProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      playingController.add(true);
      await flushEvents();

      expect(container.read(audioIsPlayingProvider).valueOrNull, isTrue);

      playingController.add(false);
      await flushEvents();

      expect(container.read(audioIsPlayingProvider).valueOrNull, isFalse);

      expect(
        states.whereType<AsyncData<bool>>().map((state) => state.value),
        containsAllInOrder(<bool>[true, false]),
      );

      verify(() => audioService.isPlayingStream).called(1);
    });

    test('exposes errors from the AudioService stream', () async {
      final failure = StateError('audio stream failed');

      when(
        () => audioService.isPlayingStream,
      ).thenAnswer((_) => Stream<bool>.error(failure));

      final errorContainer = ProviderContainer(
        overrides: [audioServiceProvider.overrideWithValue(audioService)],
      );
      addTearDown(errorContainer.dispose);

      await expectLater(
        errorContainer.read(audioIsPlayingProvider.future),
        throwsA(same(failure)),
      );

      expect(
        errorContainer.read(audioIsPlayingProvider),
        isA<AsyncError<bool>>(),
      );
    });

    test('cancels the audio stream subscription when disposed', () async {
      var wasCancelled = false;
      final controller = StreamController<bool>.broadcast(
        onCancel: () {
          wasCancelled = true;
        },
      );

      when(
        () => audioService.isPlayingStream,
      ).thenAnswer((_) => controller.stream);

      final disposableContainer = ProviderContainer(
        overrides: [audioServiceProvider.overrideWithValue(audioService)],
      );

      disposableContainer.listen(
        audioIsPlayingProvider,
        (_, _) {},
        fireImmediately: true,
      );

      await flushEvents();
      expect(controller.hasListener, isTrue);

      // Emit a value so the provider leaves loading state. While loading,
      // Riverpod keeps the source subscription alive after dispose to
      // complete `provider.future`, so cancellation is only observable
      // once data has been delivered.
      controller.add(true);
      await flushEvents();
      expect(
        disposableContainer.read(audioIsPlayingProvider).valueOrNull,
        isTrue,
      );

      disposableContainer.dispose();
      await flushEvents();

      expect(wasCancelled, isTrue);
      expect(controller.hasListener, isFalse);

      await controller.close();
    });
  });
}
