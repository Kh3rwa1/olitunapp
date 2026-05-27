import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class MockClient extends Mock implements Client {}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final Duration? loadDuration;
  final bool shouldThrow;

  FakeAudioPlayerPlatform({
    required String id,
    this.loadDuration,
    this.shouldThrow = false,
  }) : super(id);

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
    if (shouldThrow) {
      throw Exception('Mock platform load failed');
    }
    final duration = loadDuration;
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
  Duration? nextLoadDuration = const Duration(seconds: 15);
  bool shouldThrow = false;
  int initCount = 0;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    initCount++;
    return FakeAudioPlayerPlatform(
      id: request.id,
      loadDuration: nextLoadDuration,
      shouldThrow: shouldThrow,
    );
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

  group('MediaUploader Duration Probe Tests', () {
    late MediaUploader uploader;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      uploader = MediaUploader(mockClient);
    });

    test(
      'Mock a 15-second audio file (native) -> returns durationMs (15000)',
      () async {
        fakePlatform.nextLoadDuration = const Duration(seconds: 15);
        fakePlatform.shouldThrow = false;

        final file = PlatformFile(
          name: 'test.mp3',
          size: 1024,
          path: 'dummy/path/to/test.mp3',
        );

        final duration = await uploader.probeAudioDurationMs(file);
        expect(duration, equals(15000));
        expect(fakePlatform.initCount, equals(1));
      },
    );

    test(
      'On native VM: a file with null path and only bytes -> returns null safely to avoid memory loading on native',
      () async {
        final file = PlatformFile(
          name: 'web_test.wav',
          size: 2048,
          bytes: Uint8List.fromList([0, 1, 2, 3]),
        );

        final duration = await uploader.probeAudioDurationMs(file);
        expect(duration, isNull);
        expect(
          fakePlatform.initCount,
          equals(0),
        ); // Prober skipped because kIsWeb is false and path is null
      },
    );

    test(
      'Mock probe failure (throwing load exception) -> returns null safely',
      () async {
        fakePlatform.shouldThrow = true;

        final file = PlatformFile(
          name: 'corrupt.mp3',
          size: 512,
          path: 'dummy/path/to/corrupt.mp3',
        );

        final duration = await uploader.probeAudioDurationMs(file);
        expect(duration, isNull);
        expect(fakePlatform.initCount, equals(1));
      },
    );
  });
}
