import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/shared/media/media_uploader.dart';
import 'package:itun/core/storage/upload_service.dart';
import 'package:itun/core/storage/worker_media_api.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:mocktail/mocktail.dart';

class _Account extends Mock implements Account {}

class _Jwt extends Mock implements models.Jwt {}

EdgeAuth _edgeAuth(String jwt) {
  final account = _Account();
  final token = _Jwt();
  when(() => token.jwt).thenReturn(jwt);
  when(account.createJWT).thenAnswer((_) async => token);
  return EdgeAuth(account);
}

class _Sent {
  late http.BaseRequest request;
  late List<int> body;
}

WorkerMediaApi _api(
  _Sent sent, {
  int status = 201,
  Map<String, dynamic>? response,
}) {
  final client = MockClient.streaming((request, bodyStream) async {
    sent.request = request;
    sent.body = await bodyStream.expand((chunk) => chunk).toList();
    final json = response ?? {'ok': true, 'fileId': 'abc123'};
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(json))),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return WorkerMediaApi(httpClient: client, edgeAuth: _edgeAuth('admin-jwt'));
}

PlatformFile _file(String name, List<int> bytes) => PlatformFile(
  name: name,
  size: bytes.length,
  bytes: Uint8List.fromList(bytes),
);

void main() {
  const assets = CloudflareConfig.assetsEndpoint;
  const admin = CloudflareConfig.adminMediaEndpoint;

  group('Worker asset URLs', () {
    test('workerAssetUrl points at the Worker assets route', () {
      expect(workerAssetUrl('audio', 'f1'), '$assets/audio/f1');
      expect(admin, '${CloudflareConfig.baseUrl}/api/v1/admin/media');
      expect(workerAssetUrl('audio', 'f1'), isNot(contains('appwrite')));
    });
  });

  group('WorkerMediaApi', () {
    test('upload PUTs raw bytes with JWT and content type', () async {
      final sent = _Sent();
      final result = await _api(sent).uploadFile(
        file: _file('song.mp3', [1, 2, 3]),
        bucketId: 'audio',
        contentType: 'audio/mpeg',
        fileId: 'abc123',
      );

      expect(sent.request.method, 'PUT');
      expect(sent.request.url.toString(), '$admin/audio/abc123');
      expect(sent.request.headers['Authorization'], 'Bearer admin-jwt');
      expect(sent.request.headers['Content-Type'], 'audio/mpeg');
      expect(sent.request.contentLength, 3);
      expect(sent.body, [1, 2, 3]);
      expect(result.fileId, 'abc123');
      expect(result.url, '$assets/audio/abc123');
    });

    test('paid_media uploads return no public URL', () async {
      final sent = _Sent();
      final result = await _api(sent).uploadFile(
        file: _file('lesson.mp3', [1]),
        bucketId: 'paid_media',
        contentType: 'audio/mpeg',
        fileId: 'abc123',
      );
      expect(result.url, isNull);
      expect(result.fileId, 'abc123');
    });

    test('generates a 20-char id when none is given', () async {
      final sent = _Sent();
      await _api(sent).uploadFile(
        file: _file('a.png', [1]),
        bucketId: 'images',
        contentType: 'image/png',
      );
      final id = sent.request.url.pathSegments.last;
      expect(id, matches(RegExp(r'^[0-9a-f]{20}$')));
    });

    test('Worker rejections surface status and error code', () async {
      final sent = _Sent();
      final api = _api(
        sent,
        status: 413,
        response: {'ok': false, 'error': 'file_too_large', 'message': 'big'},
      );
      await expectLater(
        api.uploadFile(
          file: _file('a.mp4', [1]),
          bucketId: 'videos',
          contentType: 'video/mp4',
        ),
        throwsA(
          isA<WorkerMediaException>()
              .having((e) => e.statusCode, 'status', 413)
              .having((e) => e.code, 'code', 'file_too_large'),
        ),
      );
    });

    test('delete sends DELETE with JWT and reports removal', () async {
      final sent = _Sent();
      final deleted = await _api(
        sent,
        status: 200,
        response: {'ok': true, 'deleted': true},
      ).delete('images', 'img1');

      expect(sent.request.method, 'DELETE');
      expect(sent.request.url.toString(), '$admin/images/img1');
      expect(sent.request.headers['Authorization'], 'Bearer admin-jwt');
      expect(deleted, isTrue);
    });

    test('delete of a non-admin call throws', () async {
      final sent = _Sent();
      await expectLater(
        _api(
          sent,
          status: 403,
          response: {'ok': false, 'error': 'forbidden'},
        ).delete('images', 'img1'),
        throwsA(isA<WorkerMediaException>()),
      );
    });

    test('isReferenced queries the Worker reference check', () async {
      final sent = _Sent();
      final referenced = await _api(
        sent,
        status: 200,
        response: {'ok': true, 'referenced': true},
      ).isReferenced('f9');

      expect(sent.request.method, 'GET');
      expect(sent.request.url.toString(), '$admin/references?fileId=f9');
      expect(sent.request.headers['Authorization'], 'Bearer admin-jwt');
      expect(referenced, isTrue);
    });

    test('isReferenced throws on a malformed answer', () async {
      final sent = _Sent();
      await expectLater(
        _api(sent, status: 200, response: {'ok': true}).isReferenced('f9'),
        throwsA(isA<WorkerMediaException>()),
      );
    });
  });

  group('Upload services use the Worker', () {
    test('MediaUploadService returns the Worker asset URL', () async {
      final sent = _Sent();
      final url = await MediaUploadService(
        _api(sent),
      ).uploadMedia(_file('Hero.PNG', [7, 7]), 'Banners');

      expect(sent.request.method, 'PUT');
      expect(sent.request.url.path, startsWith('/api/v1/admin/media/images/'));
      expect(sent.request.headers['Content-Type'], 'image/png');
      expect(sent.request.headers['X-File-Name'], contains('banners-'));
      expect(url, '$assets/images/abc123');
    });

    test('MediaUploadService rethrows Worker errors', () async {
      final sent = _Sent();
      final service = MediaUploadService(
        _api(sent, status: 415, response: {'ok': false}),
      );
      await expectLater(
        service.uploadMedia(_file('a.mp3', [1]), 'audio'),
        throwsA(isA<WorkerMediaException>()),
      );
    });

    test('mediaContentTypes covers every MediaUploadService extension', () {
      for (final ext in ['mp3', 'png', 'json', 'mp4', 'svg', 'm4a', 'mov']) {
        expect(mediaContentTypes[ext], isNotNull, reason: ext);
      }
    });

    test('MediaUploader routes kinds to the same buckets', () {
      final uploader = MediaUploader(_api(_Sent()));
      expect(
        uploader.getBucketIdForTesting(ContentMediaKind.video, 'a.mp4'),
        'cover_videos',
      );
    });
  });
}
