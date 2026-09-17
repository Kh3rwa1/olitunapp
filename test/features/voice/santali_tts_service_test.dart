import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/voice/data/santali_tts_service.dart';
import 'package:itun/features/voice/data/voice_download_service.dart';

void main() {
  group('santali tts service', () {
    test('rejects empty text without touching the network', () async {
      final service = SantaliTtsService();
      final result = await service.synthesize(text: '   ', voice: 'Phulmani');
      expect(result.clip, isNull);
      expect(result.failure?.message, contains('Type something'));
    });

    test('rejects unknown voice/style locally', () async {
      final service = SantaliTtsService();
      final badVoice = await service.synthesize(text: 'ᱡᱚᱦᱟᱨ', voice: 'Nobody');
      expect(badVoice.failure, isNotNull);
      final badStyle = await service.synthesize(
        text: 'ᱡᱚᱦᱟᱨ',
        voice: 'Phulmani',
        style: 'opera',
      );
      expect(badStyle.failure, isNotNull);
    });

    test('unwraps Appwrite execution envelopes', () {
      final inner = jsonEncode({
        'success': true,
        'data': {'audioUrl': 'https://x/y.wav', 'voice': 'Phulmani'},
      });
      final envelope = jsonEncode({
        r'$id': 'exec1',
        'status': 'completed',
        'responseBody': inner,
        'responseStatusCode': 200,
      });
      final parsed = SantaliTtsService.unwrapExecutionForTest(envelope);
      expect(parsed?['success'], isTrue);
      expect(
        SantaliTtsService.unwrapExecutionForTest(inner)?['success'],
        isTrue,
      );
      expect(SantaliTtsService.unwrapExecutionForTest('not-json'), isNull);
    });
  });

  group('voice file names', () {
    test('are deterministic and filesystem-safe', () {
      expect(voiceFileNameForTest('Phulmani', 123), 'olitun-phulmani-123.wav');
      expect(voiceFileNameForTest('', 1), 'olitun-santali-1.wav');
    });
  });
}
