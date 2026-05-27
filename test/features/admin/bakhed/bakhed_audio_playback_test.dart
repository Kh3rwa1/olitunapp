import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:just_audio/just_audio.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart';
import 'package:itun/shared/models/content_item.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  String? urlLoaded;

  FakeAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    return SetPitchResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async {
    return SetShuffleModeResponse();
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    var source = request.audioSourceMessage;
    if (source is ConcatenatingAudioSourceMessage) {
      if (source.children.isNotEmpty) {
        source = source.children.first;
      }
    }
    if (source is UriAudioSourceMessage) {
      urlLoaded = source.uri;
    } else {
      try {
        final dynamic dynSource = source;
        urlLoaded = dynSource.uri as String?;
      } catch (_) {
        urlLoaded = source.id;
      }
    }
    final duration = const Duration(seconds: 10);
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: duration,
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: duration);
  }
}

class FakeJustAudioPlatform extends JustAudioPlatform {
  FakeAudioPlayerPlatform? activePlayer;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final player = FakeAudioPlayerPlatform(request.id);
    activePlayer = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeJustAudioPlatform fakePlatform;

  setUp(() {
    fakePlatform = FakeJustAudioPlatform();
    JustAudioPlatform.instance = fakePlatform;
  });

  group('bakhedAudioPlayerProvider Tests', () {
    const rhymeId = 'test_rhyme_123';
    const audioUrl = 'https://example.com/audio.mp3';

    late MockBakhedRepository mockRepository;
    late ContentItem initialItem;

    setUp(() {
      mockRepository = MockBakhedRepository();
      initialItem = ContentItem(
        id: rhymeId,
        kind: ContentKind.rhyme,
        categoryId: 'sohrai',
        title: 'Test Title',
        audioUrl: audioUrl,
        audioFileId: 'audio123',
        durationMs: 10000,
        blocks: const [],
        updatedAt: DateTime.now(),
      );

      when(
        () => mockRepository.get(rhymeId),
      ).thenAnswer((_) async => right(initialItem));
    });

    test(
      'Initializes player and loads URL when editor state is loaded',
      () async {
        final container = ProviderContainer(
          overrides: [
            bakhedRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        addTearDown(container.dispose);

        // Trigger load on editor notifier
        final notifier = container.read(
          bakhedEditorControllerProvider(rhymeId).notifier,
        );
        await notifier.load();

        // Read audio player provider and listen to keep it alive
        final subscription = container.listen(
          bakhedAudioPlayerProvider(rhymeId),
          (_, _) {},
        );
        final player = container.read(bakhedAudioPlayerProvider(rhymeId));
        expect(player, isNotNull);

        // Verify that setWebCrossOrigin compiles and runs
        player.setWebCrossOrigin(WebCrossOrigin.anonymous);

        // Await the player to finish loading and transition to ready state
        await player.processingStateStream.firstWhere(
          (state) => state == ProcessingState.ready,
        );

        expect(fakePlatform.activePlayer, isNotNull);
        expect(fakePlatform.activePlayer!.urlLoaded, equals(audioUrl));

        subscription.close();
      },
    );
  });
}
