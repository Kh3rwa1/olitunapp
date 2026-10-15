import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/media/authorized_media.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6);
  const endpoint = 'https://media.example.test/v1';
  const worker = 'https://api.example.test';
  const source = 'appwrite-storage://paid_media/file?lessonId=lesson';
  final expiry = now.add(const Duration(minutes: 5));
  final exp = expiry.millisecondsSinceEpoch ~/ 1000;
  String leaseUrl({
    String base = worker,
    String fileId = 'file',
    String? query,
  }) =>
      '$base/api/v1/media/paid/$fileId?'
      '${query ?? 'exp=$exp&uid=u1&sig=short-lived'}';
  Map<String, dynamic> response() => {
    'ok': true,
    'protocolVersion': 3,
    'transport': 'edge-signed-url',
    'bucketId': 'paid_media',
    'fileId': 'file',
    'url': leaseUrl(),
    'expiresAt': expiry.toIso8601String(),
    'mimeType': 'video/mp4',
  };
  AuthorizedMediaService service(MediaExecute execute) =>
      AuthorizedMediaService(
        execute: execute,
        endpoint: worker,
        clock: () => now,
      );

  test(
    'scoped references strip credentials, including nested encoded blocks',
    () {
      const raw =
          '$endpoint/storage/buckets/paid_media/files/file/view?token=old&project=test';
      final scoped = scopeLessonMediaValue({
        'blocks': jsonEncode([
          {'audioUrl': raw},
        ]),
        'imageUrl': raw,
      }, 'lesson');
      expect(jsonEncode(scoped), isNot(contains('token=')));
      expect(scoped['imageUrl'], source);
      final ref = PrivateMediaReference.parse(scoped['imageUrl'] as String)!;
      expect(ref.lessonId, 'lesson');
      expect(ref.bucketId, 'paid_media');
      expect(ref.fileId, 'file');
    },
  );

  test(
    'public media remains direct; private references require lesson identity',
    () async {
      var calls = 0;
      final resolver = service((_) async {
        calls++;
        return response();
      });
      expect(
        (await resolver.resolve('https://public.test/clip.mp3')).expiresAt,
        isNull,
      );
      await expectLater(
        resolver.resolve('appwrite-storage://paid_media/file'),
        throwsA(isA<MediaAccessException>()),
      );
      expect(calls, 0);
    },
  );

  test(
    'resolution uses protocol v3 and each refresh reauthorizes, never caches',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final resolver = service((body) async {
        bodies.add(body);
        return response();
      });
      final lease = await resolver.resolve(source);
      expect(lease.uri.toString(), leaseUrl());
      expect(lease.uri.queryParameters['sig'], 'short-lived');
      expect(lease.refreshAfter(now), const Duration(minutes: 4, seconds: 30));
      await resolver.resolve(source);
      expect(
        bodies,
        List.filled(2, {
          'action': 'get_media',
          'protocolVersion': 3,
          'lessonId': 'lesson',
          'bucketId': 'paid_media',
          'fileId': 'file',
        }),
      );
    },
  );

  test(
    'revocation after successful playback never falls back to previous lease',
    () async {
      var revoked = false;
      final resolver = service((_) async {
        if (revoked) throw StateError('denied token=do-not-log');
        return response();
      });
      await resolver.resolve(source);
      revoked = true;
      try {
        await resolver.resolve(source);
        fail('Expected denial');
      } catch (error) {
        expect(error, isA<MediaAccessException>());
        expect(error.toString(), isNot(contains('do-not-log')));
      }
    },
  );

  for (final override in <Map<String, dynamic>>[
    {'protocolVersion': 2},
    {'transport': 'appwrite-file-token'},
    {
      'protocolVersion': 2,
      'transport': 'appwrite-file-token',
      'url':
          '$endpoint/storage/buckets/paid_media/files/file/view?project=test&token=x',
    },
    {'bucketId': 'other'},
    {'fileId': 'other'},
    {'ok': false},
    // Foreign host, wrong scheme, credentials or fragments.
    {'url': leaseUrl(base: 'https://evil.test')},
    {'url': leaseUrl(base: 'http://api.example.test')},
    {'url': leaseUrl(base: 'https://user@api.example.test')},
    {'url': '${leaseUrl()}#frag'},
    // Cross-file grant and path tricks.
    {'url': leaseUrl(fileId: 'other')},
    {'url': leaseUrl(fileId: 'file/extra')},
    // Missing, extra or tampered signing parameters.
    {'url': leaseUrl(query: 'exp=$exp&uid=u1')},
    {'url': leaseUrl(query: 'exp=$exp&uid=u1&sig=')},
    {'url': leaseUrl(query: 'exp=$exp&sig=x')},
    {'url': leaseUrl(query: 'exp=$exp&uid=u1&sig=x&token=y')},
    {'url': leaseUrl(query: 'exp=${exp + 3600}&uid=u1&sig=x')},
    // Expired or unbounded leases.
    {'expiresAt': now.toIso8601String()},
    {'expiresAt': now.add(const Duration(seconds: 20)).toIso8601String()},
    {
      'expiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
      'url': leaseUrl(query: 'exp=${exp + 3300}&uid=u1&sig=x'),
    },
  ]) {
    test(
      'reject malformed, expired, unbounded or cross-file grant: $override',
      () async {
        final resolver = service((_) async => {...response(), ...override});
        await expectLater(
          resolver.resolve(source),
          throwsA(isA<MediaAccessException>()),
        );
      },
    );
  }
}
