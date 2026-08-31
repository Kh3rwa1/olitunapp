import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/review/admin_review_models.dart';

void main() {
  group('AdminAudioTrackRow', () {
    test('fromJson parses a full reviewContent audio row', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 'track1',
        'contentKind': 'word',
        'contentId': 'word42',
        'segmentId': '-',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'audioUrl': 'https://example.com/a.mp3',
        'provider': 'sarvam',
        'isHumanRecorded': false,
        'generationStatus': 'completed',
        'reviewStatus': 'needsReview',
        'errorMessage': null,
      });

      expect(row.id, 'track1');
      expect(row.contentKind, 'word');
      expect(row.languageCode, 'hi');
      expect(row.trackType, 'targetNormal');
      expect(row.audioUrl, 'https://example.com/a.mp3');
      expect(row.isHumanRecorded, isFalse);
      expect(row.generationStatus, 'completed');
      expect(row.reviewStatus, 'needsReview');
      expect(row.errorMessage, isNull);
    });

    test('fromJson tolerates missing/null fields', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 'track2',
        'contentKind': 'letter',
        'contentId': 'letter1',
        'languageCode': 'sat',
        'trackType': 'targetSlow',
        'reviewStatus': 'needsReview',
      });

      expect(row.audioUrl, isNull);
      expect(row.hasAudio, isFalse);
      expect(row.isApprovable, isFalse);
      expect(row.generationStatus, isNull);
    });

    test('isApprovable requires a non-empty audioUrl', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'audioUrl': '   ',
        'generationStatus': 'completed',
        'reviewStatus': 'needsReview',
      });
      expect(row.isApprovable, isFalse);
    });

    test('isApprovable passes for completed synthetic tracks with url', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'audioUrl': 'https://example.com/a.mp3',
        'generationStatus': 'completed',
        'reviewStatus': 'needsReview',
      });
      expect(row.isApprovable, isTrue);
    });

    test('isApprovable bypasses generationStatus for human recordings', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w',
        'languageCode': 'sat',
        'trackType': 'targetNormal',
        'audioUrl': 'https://example.com/human.mp3',
        'isHumanRecorded': true,
        'generationStatus': 'notRequested',
        'reviewStatus': 'needsReview',
      });
      expect(row.isApprovable, isTrue);
    });

    test('isApprovable rejects failed generation with url', () {
      final row = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'audioUrl': 'https://example.com/a.mp3',
        'generationStatus': 'failed',
        'reviewStatus': 'needsReview',
      });
      expect(row.isApprovable, isFalse);
    });

    test('displaySegmentId normalizes the "-" sentinel and null', () {
      String segFor(dynamic value) => AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'reviewStatus': 'needsReview',
        'segmentId': value,
      }).displaySegmentId;

      expect(segFor('-'), isEmpty);
      expect(segFor(null), isEmpty);
      expect(segFor(''), isEmpty);
      expect(segFor('verse-2'), 'verse-2');
    });

    test('title includes segment only when present', () {
      final withSeg = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'story',
        'contentId': 's1',
        'languageCode': 'hi',
        'trackType': 'storyNarration',
        'reviewStatus': 'needsReview',
        'segmentId': 'verse-2',
      });
      final withoutSeg = AdminAudioTrackRow.fromJson({
        'id': 't',
        'contentKind': 'word',
        'contentId': 'w1',
        'languageCode': 'hi',
        'trackType': 'targetNormal',
        'reviewStatus': 'needsReview',
        'segmentId': '-',
      });

      expect(withSeg.title, 'story · s1 · verse-2');
      expect(withoutSeg.title, 'word · w1');
    });
  });

  group('AdminLocalizedContentRow', () {
    test('fromJson parses meaning/explanation and identity', () {
      final row = AdminLocalizedContentRow.fromJson({
        'id': 'loc1',
        'contentKind': 'word',
        'contentId': 'word42',
        'languageCode': 'bn',
        'meaning': 'जल',
        'explanation': 'पीने के लिए तरल',
        'reviewStatus': 'needsReview',
      });

      expect(row.id, 'loc1');
      expect(row.languageCode, 'bn');
      expect(row.meaning, 'जल');
      expect(row.explanation, 'पीने के लिए तरल');
      expect(row.title, 'word · word42');
    });

    test('fromJson maps empty strings to null text fields', () {
      final row = AdminLocalizedContentRow.fromJson({
        'id': 'loc2',
        'contentKind': 'sentence',
        'contentId': 's9',
        'languageCode': 'or',
        'meaning': '',
        'explanation': null,
        'reviewStatus': 'needsReview',
      });

      expect(row.meaning, isNull);
      expect(row.explanation, isNull);
    });
  });

  group('queue pages', () {
    test('AdminAudioQueuePage.fromData parses documents and total', () {
      final page = AdminAudioQueuePage.fromData({
        'kind': 'audio',
        'total': 7,
        'documents': [
          {
            'id': 'a',
            'contentKind': 'word',
            'contentId': 'w',
            'languageCode': 'hi',
            'trackType': 'targetNormal',
            'reviewStatus': 'needsReview',
          },
          'not-a-map',
          {
            'id': 'b',
            'contentKind': 'word',
            'contentId': 'w2',
            'languageCode': 'hi',
            'trackType': 'explanation',
            'reviewStatus': 'needsReview',
          },
        ],
      });

      expect(page.total, 7);
      expect(page.tracks, hasLength(2));
      expect(page.tracks.first.id, 'a');
    });

    test('AdminAudioQueuePage.fromData handles missing documents', () {
      final page = AdminAudioQueuePage.fromData({'kind': 'audio'});
      expect(page.total, 0);
      expect(page.tracks, isEmpty);
    });

    test('AdminLocalizedQueuePage.fromData parses documents and total', () {
      final page = AdminLocalizedQueuePage.fromData({
        'kind': 'localized',
        'total': '3', // numeric strings tolerated
        'documents': [
          {
            'id': 'x',
            'contentKind': 'word',
            'contentId': 'w',
            'languageCode': 'sat',
            'reviewStatus': 'needsReview',
          },
        ],
      });

      expect(page.total, 3);
      expect(page.contents, hasLength(1));
      expect(page.contents.single.languageCode, 'sat');
    });
  });

  group('AdminReviewBatchResult', () {
    test('fromData aggregates per-id results', () {
      final result = AdminReviewBatchResult.fromData({
        'decision': 'approved',
        'reviewedBy': 'userA',
        'requested': 3,
        'updated': 2,
        'failed': 1,
        'results': [
          {'id': 'a', 'ok': true, 'reviewStatus': 'approved'},
          {'id': 'b', 'ok': true, 'reviewStatus': 'approved'},
          {'id': 'c', 'ok': false, 'reason': 'TRACK_NOT_APPROVABLE'},
        ],
      });

      expect(result.decision, 'approved');
      expect(result.requested, 3);
      expect(result.updated, 2);
      expect(result.failed, 1);
      expect(result.results, hasLength(3));
      expect(result.results.last.ok, isFalse);
      expect(result.results.last.reason, 'TRACK_NOT_APPROVABLE');
    });

    test('fromData tolerates missing results list', () {
      final result = AdminReviewBatchResult.fromData({
        'decision': 'rejected',
        'requested': 0,
        'updated': 0,
        'failed': 0,
      });

      expect(result.results, isEmpty);
    });
  });

  test('json round trip of a queue payload parses without error', () {
    final payload =
        jsonDecode('''
      {
        "success": true,
        "data": {
          "kind": "audio",
          "total": 1,
          "documents": [
            {
              "id": "z",
              "contentKind": "word",
              "contentId": "w1",
              "segmentId": null,
              "languageCode": "hi",
              "trackType": "targetNormal",
              "audioUrl": "https://example.com/z.mp3",
              "storageFileId": "file1",
              "provider": "sarvam",
              "model": "bulbul:v2",
              "voiceId": "vid",
              "isHumanRecorded": false,
              "generationStatus": "completed",
              "reviewStatus": "needsReview",
              "errorMessage": null,
              "reviewedBy": null,
              "reviewedAt": null,
              "updatedAt": "2026-03-03T00:00:00Z",
              "createdAt": "2026-03-01T00:00:00Z"
            }
          ]
        }
      }
    ''')
            as Map<String, dynamic>;

    final page = AdminAudioQueuePage.fromData(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
    expect(page.tracks.single.hasAudio, isTrue);
    expect(page.tracks.single.isApprovable, isTrue);
  });
}
