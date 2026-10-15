import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:mocktail/mocktail.dart';
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

    test('parses the Worker voice payload', () {
      final service = SantaliTtsService();
      final ok = service.parsePayloadForTest(
        jsonEncode({
          'success': true,
          'data': {'audioUrl': 'https://x/y.wav', 'voice': 'Phulmani'},
        }),
      );
      expect(ok.clip?.audioUrl, 'https://x/y.wav');
      expect(service.parsePayloadForTest('not-json').failure, isNotNull);
    });

    test('posts to the Worker with the session JWT', () async {
      late http.Request sent;
      final service = SantaliTtsService(
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'ok': true,
              'data': {'audioUrl': 'https://x/a.wav', 'voice': 'Phulmani'},
            }),
            200,
          );
        }),
        edgeAuth: _fixedEdgeAuth(),
      );
      final result = await service.synthesize(text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani');
      expect(result.clip?.audioUrl, 'https://x/a.wav');
      expect(sent.url.toString(), CloudflareConfig.voiceSynthesizeEndpoint);
      expect(sent.headers['Authorization'], 'Bearer test-jwt');
    });

    test('maps 401 to a sign-in prompt and surfaces Worker messages', () async {
      SantaliTtsService serviceReturning(int status, Map<String, dynamic> b) =>
          SantaliTtsService(
            client: MockClient(
              (_) async => http.Response(jsonEncode(b), status),
            ),
          );
      final unauth = await serviceReturning(401, {
        'ok': false,
      }).synthesize(text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani');
      expect(unauth.failure?.loginRequired, isTrue);

      final exhausted = await serviceReturning(503, {
        'ok': false,
        'message': 'All voice keys are out of credit or invalid.',
      }).synthesize(text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani');
      expect(exhausted.failure?.message, contains('out of credit'));
    });
  });

  group('voice file names', () {
    test('are deterministic and filesystem-safe', () {
      expect(voiceFileNameForTest('Phulmani', 123), 'olitun-phulmani-123.wav');
      expect(voiceFileNameForTest('', 1), 'olitun-santali-1.wav');
    });
  });
}

class _MockAccount extends Mock implements Account {}

EdgeAuth _fixedEdgeAuth() {
  final account = _MockAccount();
  when(account.createJWT).thenAnswer((_) async => models.Jwt(jwt: 'test-jwt'));
  return EdgeAuth(account);
}
