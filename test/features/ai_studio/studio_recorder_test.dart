import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/ai_studio/data/studio_recorder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

class _PlatformRecorder extends Mock implements AudioRecorder {}

Future<Stream<Uint8List>> _chunkStream(Invocation _) async =>
    Stream.fromIterable([
      Uint8List.fromList([1, 0, 2, 0]),
    ]);

Future<Stream<Uint8List>> _emptyStream(Invocation _) async =>
    const Stream<Uint8List>.empty();

Future<bool> _permissionGranted(Invocation _) => Future.value(true);

Future<String?> _noOutputPath(Invocation _) => Future<String?>.value();

Future<void> _completed(Invocation _) => Future<void>.value();

Future<dynamic> _unhandledPlatformCall(MethodCall _) async => null;

void main() {
  setUpAll(() => registerFallbackValue(const RecordConfig()));
  test('pcm16ToWav creates a standard 16 kHz mono PCM WAV header', () {
    final wav = pcm16ToWav(Uint8List.fromList([1, 0, 2, 0]));

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    final header = ByteData.sublistView(wav);
    expect(header.getUint16(20, Endian.little), 1);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), 16000);
    expect(header.getUint16(34, Endian.little), 16);
    expect(header.getUint32(40, Endian.little), 4);
    expect(wav.sublist(44), [1, 0, 2, 0]);
  });

  test('pcm16ToWav rejects incomplete PCM16 samples', () {
    expect(() => pcm16ToWav(Uint8List.fromList([1])), throwsArgumentError);
  });

  test(
    'studioRecorderProvider keeps one recorder across reads (start then stop)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('com.llfbandit.record/messages');
      // NB: no manual removal — the test framework resets mock handlers
      // after each test, and removing it here could run before the
      // container below is disposed.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, _unhandledPlatformCall);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(studioRecorderProvider);
      // The screen reads the provider on separate taps/frames; the same
      // instance must survive between reads or stop() can never see the
      // recording started by start().
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = container.read(studioRecorderProvider);

      expect(identical(first, second), isTrue);
    },
  );

  test('start then stop returns a playable microphone WAV', () async {
    final platform = _PlatformRecorder();
    when(platform.hasPermission).thenAnswer(_permissionGranted);
    when(() => platform.startStream(any())).thenAnswer(_chunkStream);
    when(platform.stop).thenAnswer(_noOutputPath);
    final recorder = PcmStudioRecorder(recorder: platform);

    await recorder.start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final input = await recorder.stop();

    expect(input, isNotNull);
    expect(input!.name, 'microphone.wav');
    expect(String.fromCharCodes(input.bytes.sublist(0, 4)), 'RIFF');
    expect(recorder.isRecording, isFalse);
  });

  test('failed stop resets state so the next recording can start', () async {
    final platform = _PlatformRecorder();
    when(platform.hasPermission).thenAnswer(_permissionGranted);
    when(platform.cancel).thenAnswer(_completed);
    when(platform.dispose).thenAnswer(_completed);
    when(() => platform.startStream(any())).thenAnswer(_emptyStream);
    when(platform.stop).thenThrow(Exception('platform stop failed'));
    final recorder = PcmStudioRecorder(recorder: platform);

    await recorder.start();
    await expectLater(recorder.stop(), throwsException);
    expect(recorder.isRecording, isFalse);

    when(platform.stop).thenAnswer(_noOutputPath);
    await recorder.start();
    expect(recorder.isRecording, isTrue);
    await recorder.cancel();
    expect(recorder.isRecording, isFalse);
  });
}
