import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/worker_media_api.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/data/gamification_cms_api.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:mocktail/mocktail.dart';

class _Account extends Mock implements Account {}

class _Jwt extends Mock implements models.Jwt {}

class _Media extends Mock implements WorkerMediaApi {}

class _Network extends Mock implements NetworkInfo {}

EdgeAuth _edgeAuth() {
  final account = _Account();
  final token = _Jwt();
  when(() => token.jwt).thenReturn('admin-jwt');
  when(account.createJWT).thenAnswer((_) async => token);
  return EdgeAuth(account);
}

/// Records every request and answers with [respond].
class _Recorder {
  _Recorder(this.respond);

  final http.Response Function(http.Request request) respond;
  final requests = <http.Request>[];

  late final client = MockClient((request) async {
    requests.add(request);
    return respond(request);
  });
}

http.Response _ok(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode({'ok': true, ...body}), status);

void main() {
  group('GamificationCmsApi', () {
    test('listRows GETs the collection with the admin JWT', () async {
      final rec = _Recorder(
        (_) => _ok({
          'rows': [
            {'id': 'karam_listener', 'badgeId': 'karam_listener'},
          ],
        }),
      );
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      final rows = await api.listRows('badges');

      final req = rec.requests.single;
      expect(req.method, 'GET');
      expect(
        req.url.toString(),
        '${CloudflareConfig.adminCmsRowsEndpoint}/badges',
      );
      expect(req.headers['Authorization'], 'Bearer admin-jwt');
      expect(rows.single['id'], 'karam_listener');
    });

    test('listRows scopes Bakhed children with bakhedId', () async {
      final rec = _Recorder((_) => _ok({'rows': []}));
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      await api.listRows('bakhed_lyrics', bakhedId: 'bk 1');

      final url = rec.requests.single.url;
      expect(url.path, endsWith('/api/v1/admin/cms/rows/bakhed_lyrics'));
      expect(url.queryParameters, {'bakhedId': 'bk 1'});
    });

    test('upsertRow PUTs {data, createOnly} as JSON', () async {
      final rec = _Recorder(
        (_) => _ok({
          'row': {'id': 'bravo_johar', 'title': 'Johar!'},
        }, 201),
      );
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      final row = await api.upsertRow('bravo_messages', 'bravo_johar', {
        'title': 'Johar!',
        'status': 'published',
      }, createOnly: true);

      final req = rec.requests.single;
      expect(req.method, 'PUT');
      expect(
        req.url.toString(),
        '${CloudflareConfig.adminCmsRowsEndpoint}/bravo_messages/bravo_johar',
      );
      expect(req.headers['Authorization'], 'Bearer admin-jwt');
      expect(req.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(req.body), {
        'data': {'title': 'Johar!', 'status': 'published'},
        'createOnly': true,
      });
      expect(row['id'], 'bravo_johar');
    });

    test('upsertRow omits createOnly for plain updates', () async {
      final rec = _Recorder((_) => _ok({'row': {}}));
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      await api.upsertRow('badges', 'b1', {'status': 'archived'});

      expect(jsonDecode(rec.requests.single.body), {
        'data': {'status': 'archived'},
      });
    });

    test('deleteRow sends DELETE for one row', () async {
      final rec = _Recorder((_) => _ok({}));
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      await api.deleteRow('bakhed_cultural_notes', 'n/1');

      final req = rec.requests.single;
      expect(req.method, 'DELETE');
      expect(
        req.url.toString(),
        '${CloudflareConfig.adminCmsRowsEndpoint}/bakhed_cultural_notes/n%2F1',
      );
    });

    test('Worker validation errors surface in the exception', () async {
      final rec = _Recorder(
        (_) => http.Response(
          jsonEncode({
            'ok': false,
            'message': 'Invalid row',
            'errors': ['target must be >= 1.'],
          }),
          400,
        ),
      );
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      await expectLater(
        api.upsertRow('badges', 'b1', {'target': 0}),
        throwsA(
          isA<CmsApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('target')),
        ),
      );
    });

    test('non-admin 403 is an error, never an empty list', () async {
      final rec = _Recorder(
        (_) => http.Response(jsonEncode({'ok': false}), 403),
      );
      final api = GamificationCmsApi(
        httpClient: rec.client,
        edgeAuth: _edgeAuth(),
      );

      await expectLater(
        api.listRows('badges'),
        throwsA(isA<CmsApiException>().having((e) => e.statusCode, 's', 403)),
      );
    });
  });

  group('BakhedRepository on the Worker', () {
    late _Media media;
    late _Network network;

    setUp(() {
      media = _Media();
      network = _Network();
      when(() => network.isConnected).thenAnswer((_) async => true);
    });

    BakhedRepository repo(_Recorder rec) => BakhedRepository(
      api: GamificationCmsApi(httpClient: rec.client, edgeAuth: _edgeAuth()),
      media: media,
      networkInfo: network,
    );

    test(
      'delete cascades with one Worker DELETE, then drops the audio',
      () async {
        final rec = _Recorder(
          (_) => _ok({
            'id': 'bk1',
            'deleted': {
              'rhymes': 1,
              'bakhed_lyrics': 2,
              'bakhed_vocabulary': 1,
              'bakhed_cultural_notes': 1,
            },
            'audioFileId': 'aud1',
          }),
        );
        when(() => media.delete(any(), any())).thenAnswer((_) async => true);

        final result = await repo(rec).delete('bk1');

        expect(result.isRight(), isTrue);
        final req = rec.requests.single;
        expect(req.method, 'DELETE');
        expect(
          req.url.toString(),
          '${CloudflareConfig.adminCmsBakhedEndpoint}/bk1',
        );
        expect(req.headers['Authorization'], 'Bearer admin-jwt');
        verify(() => media.delete('audio', 'aud1')).called(1);
      },
    );

    test('delete failure is a ServerFailure and keeps the audio', () async {
      final rec = _Recorder(
        (_) => http.Response(jsonEncode({'ok': false}), 500),
      );

      final result = await repo(rec).delete('bk1');

      expect(result.isLeft(), isTrue);
      verifyNever(() => media.delete(any(), any()));
    });

    test('get maps a Worker 404 to ServerFailure code 404', () async {
      final rec = _Recorder(
        (_) => http.Response(
          jsonEncode({'ok': false, 'message': 'Bakhed not found'}),
          404,
        ),
      );

      final result = await repo(rec).get('new_bk');

      final failure = result.swap().getOrElse((_) => throw StateError('ok'));
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 404);
    });

    test('upsert PUTs the rhyme with its updatedAt token', () async {
      final rec = _Recorder((_) => _ok({'item': {}}));
      final item = ContentItem(
        id: 'bk1',
        kind: ContentKind.rhyme,
        categoryId: 'karam',
        title: 'Karam Bakhed',
        blocks: const [],
        updatedAt: DateTime.utc(2026, 10, 15, 8),
      );

      final result = await repo(rec).upsert(item);

      expect(result, right<Failure, Unit>(unit));
      final req = rec.requests.single;
      expect(req.method, 'PUT');
      expect(
        req.url.toString(),
        '${CloudflareConfig.adminCmsBakhedEndpoint}/bk1',
      );
      final data = (jsonDecode(req.body) as Map)['data'] as Map;
      expect(data['titleLatin'], 'Karam Bakhed');
      expect(data['updatedAt'], '2026-10-15T08:00:00.000Z');
    });

    test('getLyrics reads one Bakhed and orders by lineIndex', () async {
      final rec = _Recorder(
        (_) => _ok({
          'rows': [
            {'id': 'l2', 'bakhedId': 'bk1', 'lineIndex': 1, 'latin': 'two'},
            {'id': 'l1', 'bakhedId': 'bk1', 'lineIndex': 0, 'latin': 'one'},
          ],
        }),
      );

      final result = await repo(rec).getLyrics('bk1');

      final lines = result.getOrElse((_) => const []);
      expect(lines.map((l) => l.id), ['l1', 'l2']);
      expect(rec.requests.single.url.queryParameters['bakhedId'], 'bk1');
    });

    test('getCulturalNotes uses the row id as noteId', () async {
      final rec = _Recorder(
        (_) => _ok({
          'rows': [
            {
              'id': 'n1',
              'bakhedId': 'bk1',
              'title': 'Karam',
              'body': 'Celebrated in Bhado.',
              'isPublished': true,
            },
          ],
        }),
      );

      final result = await repo(rec).getCulturalNotes('bk1');

      final notes = result.getOrElse((_) => const []);
      expect(notes.single.noteId, 'n1');
      expect(notes.single.isPublished, isTrue);
    });
  });
}
