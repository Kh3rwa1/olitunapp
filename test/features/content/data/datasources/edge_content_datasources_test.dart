import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/content/data/datasources/audio_track_remote_datasource.dart';
import 'package:itun/features/content/data/datasources/localized_content_remote_datasource.dart';
import 'package:itun/features/content/data/datasources/story_segment_remote_datasource.dart';

/// Records Worker requests and answers each with [respond].
class _Worker {
  _Worker(this.respond);

  final http.Response Function(Uri url) respond;
  final requests = <Uri>[];

  late final MockClient client = MockClient((request) async {
    requests.add(request.url);
    return respond(request.url);
  });
}

http.Response _ok(String key, List<Map<String, dynamic>> rows) => http.Response(
  jsonEncode({'ok': true, 'total': rows.length, key: rows}),
  200,
);

void main() {
  group('AudioTrackRemoteDataSourceImpl', () {
    test('getAllTracks queries the Worker by kind and id', () async {
      final worker = _Worker(
        (_) => _ok('tracks', [
          {
            'id': 't1',
            'contentKind': 'word',
            'contentId': 'w1',
            'languageCode': 'sat',
            'trackType': 'targetNormal',
            'audioUrl': 'https://cdn/x.mp3',
            'reviewStatus': 'approved',
            'durationMs': 1200,
          },
        ]),
      );
      final ds = AudioTrackRemoteDataSourceImpl(worker.client);

      final tracks = await ds.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(tracks.single.id, 't1');
      expect(tracks.single.trackTypeName, 'targetNormal');
      expect(tracks.single.durationMs, 1200);
      final url = worker.requests.single;
      expect(url.path, '/api/v1/audio-tracks');
      expect(url.queryParameters['contentKind'], 'word');
      expect(url.queryParametersAll['contentId'], ['w1']);
    });

    test('getTracksByType forwards trackType and languageCode', () async {
      final worker = _Worker((_) => _ok('tracks', const []));
      final ds = AudioTrackRemoteDataSourceImpl(worker.client);

      final tracks = await ds.getTracksByType(
        contentKind: 'word',
        contentId: 'w1',
        trackType: 'teachingMeaning',
        languageCode: 'hi',
      );

      expect(tracks, isEmpty);
      final url = worker.requests.single;
      expect(url.queryParameters['trackType'], 'teachingMeaning');
      expect(url.queryParameters['languageCode'], 'hi');
    });

    test('getTracksForItems chunks ids at 100 per request', () async {
      final worker = _Worker((_) => _ok('tracks', const []));
      final ds = AudioTrackRemoteDataSourceImpl(worker.client);
      final ids = List.generate(150, (i) => 'w$i');

      final tracks = await ds.getTracksForItems(
        contentKind: 'word',
        contentIds: ids,
      );

      expect(tracks, isEmpty);
      expect(worker.requests, hasLength(2));
      expect(
        worker.requests[0].queryParametersAll['contentId'],
        hasLength(100),
      );
      expect(worker.requests[1].queryParametersAll['contentId'], hasLength(50));
    });

    test('getTracksForItems skips the network for no ids', () async {
      final worker = _Worker((_) => _ok('tracks', const []));
      final ds = AudioTrackRemoteDataSourceImpl(worker.client);

      await ds.getTracksForItems(contentKind: 'word', contentIds: const []);

      expect(worker.requests, isEmpty);
    });

    test('surfaces Worker errors as ServerException', () async {
      final worker = _Worker((_) => http.Response('boom', 500));
      final ds = AudioTrackRemoteDataSourceImpl(worker.client);

      await expectLater(
        ds.getAllTracks(contentKind: 'word', contentId: 'w1'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 500)),
      );
    });
  });

  group('LocalizedContentRemoteDataSourceImpl', () {
    test('getLocalizationsForLanguage hits the Worker route', () async {
      final worker = _Worker(
        (_) => _ok('localizations', [
          {
            'id': 'l1',
            'contentKind': 'word',
            'contentId': 'w1',
            'languageCode': 'hi',
            'meaning': 'paani',
            'reviewStatus': 'approved',
            'version': 2,
          },
        ]),
      );
      final ds = LocalizedContentRemoteDataSourceImpl(worker.client);

      final rows = await ds.getLocalizationsForLanguage(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(rows.single.meaning, 'paani');
      expect(rows.single.version, 2);
      final url = worker.requests.single;
      expect(url.path, '/api/v1/localized-contents');
      expect(url.queryParameters['languageCode'], 'hi');
      expect(url.queryParametersAll['contentId'], ['w1']);
    });

    test('empty Worker list is a valid empty result', () async {
      final worker = _Worker((_) => _ok('localizations', const []));
      final ds = LocalizedContentRemoteDataSourceImpl(worker.client);

      final rows = await ds.getLocalizations(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(rows, isEmpty);
    });

    test('getLocalizationsForIds chunks ids', () async {
      final worker = _Worker((_) => _ok('localizations', const []));
      final ds = LocalizedContentRemoteDataSourceImpl(worker.client);

      await ds.getLocalizationsForIds(
        contentKind: 'word',
        contentIds: List.generate(101, (i) => 'w$i'),
        languageCode: 'en',
      );

      expect(worker.requests, hasLength(2));
    });

    test('malformed envelope surfaces ServerException', () async {
      final worker = _Worker((_) => http.Response('{"ok":false}', 200));
      final ds = LocalizedContentRemoteDataSourceImpl(worker.client);

      await expectLater(
        ds.getLocalizations(contentKind: 'word', contentId: 'w1'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('StorySegmentRemoteDataSourceImpl', () {
    test('returns the story segments ordered by order', () async {
      final worker = _Worker(
        (_) => _ok('segments', [
          {
            'id': 's2',
            'storyId': 'story1',
            'order': 2,
            'textOlChiki': 'b',
            'translations': '{"en":"two"}',
          },
          {'id': 's1', 'storyId': 'story1', 'order': 1, 'textOlChiki': 'a'},
          {'id': 'x', 'storyId': 'other', 'order': 0, 'textOlChiki': 'x'},
        ]),
      );
      final ds = StorySegmentRemoteDataSourceImpl(worker.client);

      final segments = await ds.getSegmentsForStory(' story1 ');

      expect(segments.map((s) => s.id), ['s1', 's2']);
      expect(segments.last.translations, {'en': 'two'});
      final url = worker.requests.single;
      expect(url.path, '/api/v1/story-segments');
      expect(url.queryParameters['storyId'], 'story1');
    });

    test('blank story id never hits the network', () async {
      final worker = _Worker((_) => _ok('segments', const []));
      final ds = StorySegmentRemoteDataSourceImpl(worker.client);

      expect(await ds.getSegmentsForStory('  '), isEmpty);
      expect(worker.requests, isEmpty);
    });

    test('transport failure surfaces ServerException', () async {
      final ds = StorySegmentRemoteDataSourceImpl(
        MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(
        ds.getSegmentsForStory('story1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
