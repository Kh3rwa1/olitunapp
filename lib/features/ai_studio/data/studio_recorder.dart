import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import 'ai_studio_service.dart';

const _sampleRate = 16000;
const _channels = 1;
const _bitsPerSample = 16;

/// Narrow recording seam so the Studio UI is testable without platform audio.
abstract class StudioRecorder {
  bool get isRecording;

  /// Requests microphone permission and begins a 16 kHz mono PCM16 stream.
  Future<void> start();

  /// Stops and returns a standards-compliant WAV input for Sarvam STT.
  Future<StudioInput?> stop();

  Future<void> cancel();
  Future<void> dispose();
}

class PcmStudioRecorder implements StudioRecorder {
  PcmStudioRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final List<Uint8List> _chunks = <Uint8List>[];
  StreamSubscription<Uint8List>? _subscription;
  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> start() async {
    if (_isRecording) return;
    if (!await _recorder.hasPermission()) {
      throw const StudioException('MIC_PERMISSION');
    }
    await _subscription?.cancel();
    _subscription = null;
    _chunks.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _channels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _subscription = stream.listen(_chunks.add);
    _isRecording = true;
  }

  @override
  Future<StudioInput?> stop() async {
    if (!_isRecording) return null;
    try {
      await _recorder.stop();
    } finally {
      // Always release the stream subscription and reset state, even when
      // the platform stop fails. Otherwise the recorder wedges in a
      // recording state and every later start/stop operates on a dead
      // stream.
      await _subscription?.cancel();
      _subscription = null;
      _isRecording = false;
    }

    if (_chunks.isEmpty) return null;
    final pcm = BytesBuilder(copy: false);
    for (final chunk in _chunks) {
      pcm.add(chunk);
    }
    _chunks.clear();
    final bytes = pcm.takeBytes();
    if (bytes.isEmpty || bytes.length.isOdd) return null;
    return StudioInput(bytes: pcm16ToWav(bytes), name: 'microphone.wav');
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _chunks.clear();
    _isRecording = false;
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}

/// Wraps raw signed little-endian PCM16 samples in a RIFF/WAV container.
///
/// The server validates this exact format and derives the recording duration
/// from its frame count; callers never supply a trusted duration field.
Uint8List pcm16ToWav(Uint8List pcm) {
  if (pcm.isEmpty || pcm.length.isOdd) {
    throw ArgumentError.value(
      pcm,
      'pcm',
      'Must contain complete PCM16 samples.',
    );
  }
  final wav = Uint8List(44 + pcm.length);
  final header = ByteData.sublistView(wav);
  wav.setRange(0, 4, 'RIFF'.codeUnits);
  header.setUint32(4, 36 + pcm.length, Endian.little);
  wav.setRange(8, 12, 'WAVE'.codeUnits);
  wav.setRange(12, 16, 'fmt '.codeUnits);
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, _channels, Endian.little);
  header.setUint32(24, _sampleRate, Endian.little);
  header.setUint32(28, _sampleRate * _channels * 2, Endian.little);
  header.setUint16(32, _channels * 2, Endian.little);
  header.setUint16(34, _bitsPerSample, Endian.little);
  wav.setRange(36, 40, 'data'.codeUnits);
  header.setUint32(40, pcm.length, Endian.little);
  wav.setRange(44, wav.length, pcm);
  return wav;
}

// The Studio screen reads this provider on separate taps/frames (record
// start, then record stop) without ever watching it. It must be a plain
// app-lifetime provider: as an autoDispose provider it would be disposed
// between those reads (no listeners), which cancels the in-flight recording
// and makes stop() run on a fresh idle instance that always returns null —
// i.e. "No speech was captured" on every attempt.
final studioRecorderProvider = Provider<StudioRecorder>((ref) {
  final recorder = PcmStudioRecorder();
  ref.onDispose(() => unawaited(recorder.dispose()));
  return recorder;
});
