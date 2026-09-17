import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/ai_studio/data/studio_recorder.dart';

void main() {
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
}
