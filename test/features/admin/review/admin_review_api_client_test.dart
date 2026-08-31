import 'dart:convert';

import 'package:appwrite/enums.dart' as appwrite_enums;
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/review/admin_review_api_client.dart';

/// A canned [AdminReviewExecutor] recording every request and
/// replying with a queued [Execution] response.
class _FakeExecutor implements AdminReviewExecutor {
  _FakeExecutor({this.statusCode = 200, required this.responseBody});

  final int statusCode;
  final String responseBody;

  final List<Map<String, dynamic>> requests = [];

  @override
  Future<appwrite_models.Execution> createExecution(
    String functionId, {
    required String body,
  }) async {
    requests.add({
      'functionId': functionId,
      'body': jsonDecode(body) as Map<String, dynamic>,
    });
    return appwrite_models.Execution(
      $id: 'exec1',
      $createdAt: '2026-03-03T00:00:00Z',
      $updatedAt: '2026-03-03T00:00:00Z',
      $permissions: [],
      functionId: functionId,
      deploymentId: 'dep1',
      trigger: appwrite_enums.ExecutionTrigger.http,
      status: appwrite_enums.ExecutionStatus.completed,
      requestMethod: 'POST',
      requestPath: '/',
      requestHeaders: [],
      responseStatusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: [],
      logs: '',
      errors: '',
      duration: 0.1,
    );
  }
}

String _okData(Map<String, dynamic> data) =>
    jsonEncode({'success': true, 'data': data});

void main() {
  group('AdminReviewApiClient', () {
    test('listAudioTracks posts list_audio with default filters', () async {
      final executor = _FakeExecutor(
        responseBody: _okData({
          'kind': 'audio',
          'total': 1,
          'documents': [
            {
              'id': 'a',
              'contentKind': 'word',
              'contentId': 'w1',
              'languageCode': 'hi',
              'trackType': 'targetNormal',
              'audioUrl': 'https://example.com/a.mp3',
              'generationStatus': 'completed',
              'reviewStatus': 'needsReview',
            },
          ],
        }),
      );
      final client = AdminReviewApiClient(executor: executor);

      final page = await client.listAudioTracks(languageCode: 'hi');

      expect(executor.requests.single['functionId'], 'reviewContent');
      final body = executor.requests.single['body'] as Map<String, dynamic>;
      expect(body['action'], 'list_audio');
      expect(body['reviewStatus'], 'needsReview');
      expect(body['languageCode'], 'hi');
      expect(body['limit'], 25);
      expect(body['offset'], 0);
      expect(body.containsKey('contentKind'), isFalse);
      expect(page.total, 1);
      expect(page.tracks.single.id, 'a');
    });

    test(
      'listLocalizedContents posts list_localized without generation filter',
      () async {
        final executor = _FakeExecutor(
          responseBody: _okData({
            'kind': 'localized',
            'total': 2,
            'documents': [
              {
                'id': 'l1',
                'contentKind': 'word',
                'contentId': 'w1',
                'languageCode': 'bn',
                'meaning': 'জল',
                'reviewStatus': 'needsReview',
              },
              {
                'id': 'l2',
                'contentKind': 'word',
                'contentId': 'w2',
                'languageCode': 'or',
                'meaning': 'ଜଳ',
                'reviewStatus': 'needsReview',
              },
            ],
          }),
        );
        final client = AdminReviewApiClient(executor: executor);

        final page = await client.listLocalizedContents(
          reviewStatus: 'approved',
          contentKind: 'word',
          limit: 10,
          offset: 25,
        );

        final body = executor.requests.single['body'] as Map<String, dynamic>;
        expect(body['action'], 'list_localized');
        expect(body['reviewStatus'], 'approved');
        expect(body['contentKind'], 'word');
        expect(body['limit'], 10);
        expect(body['offset'], 25);
        expect(body.containsKey('generationStatus'), isFalse);
        expect(page.total, 2);
        expect(page.contents, hasLength(2));
      },
    );

    test('approveAudio posts approve_audio with ids', () async {
      final executor = _FakeExecutor(
        responseBody: _okData({
          'decision': 'approved',
          'requested': 2,
          'updated': 1,
          'failed': 1,
          'results': [
            {'id': 'a', 'ok': true},
            {'id': 'b', 'ok': false, 'reason': 'TRACK_NOT_APPROVABLE'},
          ],
        }),
      );
      final client = AdminReviewApiClient(executor: executor);

      final result = await client.approveAudio(['a', 'b']);

      final body = executor.requests.single['body'] as Map<String, dynamic>;
      expect(body['action'], 'approve_audio');
      expect(body['ids'], ['a', 'b']);
      expect(result.updated, 1);
      expect(result.failed, 1);
      expect(result.results.last.reason, 'TRACK_NOT_APPROVABLE');
    });

    test('rejectLocalized posts reject_localized with ids', () async {
      final executor = _FakeExecutor(
        responseBody: _okData({
          'decision': 'rejected',
          'requested': 1,
          'updated': 1,
          'failed': 0,
          'results': [
            {'id': 'x', 'ok': true},
          ],
        }),
      );
      final client = AdminReviewApiClient(executor: executor);

      await client.rejectLocalized(['x']);

      final body = executor.requests.single['body'] as Map<String, dynamic>;
      expect(body['action'], 'reject_localized');
      expect(body['ids'], ['x']);
    });

    test('throws AdminReviewException on non-2xx status', () async {
      final executor = _FakeExecutor(
        statusCode: 403,
        responseBody: jsonEncode({
          'success': false,
          'error': 'FORBIDDEN',
          'message': 'Admin team membership required.',
        }),
      );
      final client = AdminReviewApiClient(executor: executor);

      await expectLater(
        client.listAudioTracks(),
        throwsA(
          isA<AdminReviewException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.code, 'code', 'FORBIDDEN')
              .having(
                (e) => e.message,
                'message',
                'Admin team membership required.',
              ),
        ),
      );
    });

    test('throws on success:false payload', () async {
      final executor = _FakeExecutor(
        responseBody: jsonEncode({
          'success': false,
          'error': 'INVALID_INPUT',
          'message': 'ids is required.',
        }),
      );
      final client = AdminReviewApiClient(executor: executor);

      await expectLater(
        client.approveAudio(['a']),
        throwsA(isA<AdminReviewException>()),
      );
    });

    test('throws on empty response body', () async {
      final executor = _FakeExecutor(responseBody: '');
      final client = AdminReviewApiClient(executor: executor);

      await expectLater(
        client.listAudioTracks(),
        throwsA(isA<AdminReviewException>()),
      );
    });

    test('throws on malformed data payload', () async {
      final executor = _FakeExecutor(
        responseBody: jsonEncode({'success': true, 'data': 'not-a-map'}),
      );
      final client = AdminReviewApiClient(executor: executor);

      await expectLater(
        client.listAudioTracks(),
        throwsA(isA<AdminReviewException>()),
      );
    });

    test('rejects empty id lists client-side', () async {
      final executor = _FakeExecutor(responseBody: _okData({}));
      final client = AdminReviewApiClient(executor: executor);

      await expectLater(
        client.approveAudio([]),
        throwsA(isA<AdminReviewException>()),
      );
      await expectLater(
        client.rejectLocalized([]),
        throwsA(isA<AdminReviewException>()),
      );
      expect(executor.requests, isEmpty);
    });

    test('enforces the 50-id batch cap client-side', () async {
      final executor = _FakeExecutor(responseBody: _okData({}));
      final client = AdminReviewApiClient(executor: executor);
      final fiftyOne = List<String>.generate(51, (i) => 'id$i');

      await expectLater(
        client.approveAudio(fiftyOne),
        throwsA(isA<AdminReviewException>()),
      );
      expect(executor.requests, isEmpty);

      // Exactly 50 is allowed through to the executor.
      final fifty = fiftyOne.sublist(0, 50);
      await client.rejectAudio(fifty);
      expect(executor.requests, hasLength(1));
    });

    test('maxBatchIds constant matches backend cap', () {
      expect(AdminReviewApiClient.maxBatchIds, 50);
      expect(AdminReviewApiClient.functionId, 'reviewContent');
    });
  });
}
