// Review state schema migration (P12): old version data -> upgrade ->
// new version -> review state preserved. Learner progress must survive
// app updates.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('schema migration', () {
    test(
      'legacy v1 flat map (no version key) migrates to v2, preserved',
      () async {
        // A v1-era payload: flat itemId -> state, no schemaVersion wrapper.
        final legacy = jsonEncode({
          'w1': {
            'itemId': 'w1',
            'itemType': 'word',
            'introducedAt': '2026-01-01T09:00:00.000Z',
            'nextReviewAt': '2026-01-02T09:00:00.000Z',
            'intervalDays': 1.0,
            'successfulRecalls': 2,
            'masteryState': 'review',
          },
        });
        SharedPreferences.setMockInitialValues({
          ReviewStore.storageKey: legacy,
        });
        final prefs = await SharedPreferences.getInstance();

        final store = await ReviewStore.load(prefs);
        // Review state preserved through the upgrade.
        expect(store.get('w1')?.itemId, 'w1');
        expect(store.get('w1')?.successfulRecalls, 2);
        expect(store.get('w1')?.masteryState, MasteryState.review);
        expect(store.get('w1')?.nextReviewAt, DateTime.utc(2026, 1, 2, 9));

        // Next persist writes the versioned v2 format (explicit durability:
        // pure mutations never persist implicitly).
        store.adoptRemote(store.get('w1')!);
        await store.persist();
        final saved =
            jsonDecode(prefs.getString(ReviewStore.storageKey)!) as Map;
        expect(saved['schemaVersion'], ReviewStore.schemaVersion);
        expect((saved['items'] as Map).keys, contains('w1'));
      },
    );

    test('current v2 format loads unchanged (no migration loss)', () async {
      final v2 = jsonEncode({
        'schemaVersion': 2,
        'items': {
          'w1': {
            'itemId': 'w1',
            'itemType': 'word',
            'introducedAt': '2026-01-01T09:00:00.000Z',
            'nextReviewAt': '2026-01-02T09:00:00.000Z',
            'masteryState': 'review',
          },
        },
      });
      SharedPreferences.setMockInitialValues({ReviewStore.storageKey: v2});
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.get('w1')?.masteryState, MasteryState.review);
    });

    test('future version data loads best-effort (never throws)', () async {
      // A hypothetical v3 payload: loader reads the items map regardless.
      final future = jsonEncode({
        'schemaVersion': 3,
        'items': {
          'w1': {
            'itemId': 'w1',
            'itemType': 'word',
            'introducedAt': '2026-01-01T09:00:00.000Z',
            'nextReviewAt': '2026-01-02T09:00:00.000Z',
            'masteryState': 'review',
          },
        },
      });
      SharedPreferences.setMockInitialValues({ReviewStore.storageKey: future});
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.get('w1')?.itemId, 'w1');
    });

    test('corrupt v2 wrapper degrades gracefully', () async {
      SharedPreferences.setMockInitialValues({
        ReviewStore.storageKey: 'not-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.all(), isEmpty);
    });

    test('mixed corrupt/good entries: good ones survive the upgrade', () async {
      final legacy = jsonEncode({
        'good': {
          'itemId': 'good',
          'itemType': 'word',
          'introducedAt': '2026-01-01T09:00:00.000Z',
          'nextReviewAt': '2026-01-02T09:00:00.000Z',
          'masteryState': 'review',
        },
        'bad': 'garbage',
      });
      SharedPreferences.setMockInitialValues({ReviewStore.storageKey: legacy});
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.get('good')?.itemId, 'good');
      expect(store.all(), hasLength(1));
    });
  });
}
