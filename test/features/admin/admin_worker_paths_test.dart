import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_dashboard_api.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/auth/admin_functions_client.dart';
import 'package:itun/features/admin/presentation/access/controllers/admin_access_controller.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_models.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_screen.dart';
import 'package:itun/features/admin/presentation/gamification/views/gamification_analytics_view.dart';
import 'package:itun/features/admin/presentation/review/admin_review_api_client.dart';
import 'package:itun/shared/providers/dashboard_metrics_provider.dart';

/// Minimal host for the admin functions mixin, wired to a fake Worker.
class _AdminService with AdminFunctionsMixin {
  _AdminService(this.edgeFunctions);

  @override
  final AppwriteFunctionsService edgeFunctions;

  @override
  Future<void> restoreWebSession() async {}
}

class _FakeDashboardApi extends Fake implements AdminDashboardApi {
  Map<String, List<Map<String, dynamic>>> activity = const {};
  AdminAnalyticsData analyticsData = const AdminAnalyticsData(
    rollups: [],
    events: [],
    eventsTruncated: false,
  );
  final analyticsCalls = <(String, String)>[];

  @override
  Future<Map<String, List<Map<String, dynamic>>>> recentActivity() async =>
      activity;

  @override
  Future<AdminAnalyticsData> analytics({
    required String startKey,
    required String endKey,
  }) async {
    analyticsCalls.add((startKey, endKey));
    return analyticsData;
  }
}

void main() {
  group('Admin maintenance / access on the Worker', () {
    late List<http.Request> requests;

    _AdminService serviceAnswering(int status, Object body) {
      requests = [];
      return _AdminService(
        AppwriteFunctionsService(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(jsonEncode(body), status);
          }),
        ),
      );
    }

    test('backup_content posts the action to /admin/maintenance', () async {
      final service = serviceAnswering(200, {
        'success': true,
        'backup': {'fileId': 'b20261015T000000000Z-abcdef'},
      });

      final result = await service.executeAdminMaintenance(
        action: 'backup_content',
        confirmation: 'BACKUP CONTENT',
      );

      expect(requests.single.url.path, '/api/v1/admin/maintenance');
      expect(jsonDecode(requests.single.body), {
        'action': 'backup_content',
        'confirmation': 'BACKUP CONTENT',
      });
      expect(
        adminMaintenanceBackupFileId(result),
        'b20261015T000000000Z-abcdef',
      );
    });

    test('a 400 for an unknown action is an error, not success', () async {
      final service = serviceAnswering(400, {
        'success': false,
        'message': 'Unsupported admin maintenance action.',
      });

      await expectLater(
        service.executeAdminMaintenance(action: 'nope', confirmation: ''),
        throwsA(
          isA<AppwriteException>()
              .having((e) => e.code, 'code', 400)
              .having(
                (e) => e.message,
                'message',
                'Unsupported admin maintenance action.',
              ),
        ),
      );
    });

    test('a non-JSON gateway error still throws a typed error', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 502,
          body: '<html>Bad gateway</html>',
        ),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 502)),
      );
    });

    test('admin access summary goes to /admin/access', () async {
      final service = serviceAnswering(200, {
        'ok': true,
        'team': {'teamId': 'admins'},
        'admins': [],
      });

      final data = await service.executeAdminAccess({'action': 'summary'});

      expect(requests.single.url.path, '/api/v1/admin/access');
      expect(data['team'], {'teamId': 'admins'});
    });

    test('add_admin 501 carries the unavailable type and message', () async {
      final service = serviceAnswering(501, {
        'ok': false,
        'error': 'UNAVAILABLE',
        'message': 'Adding admins is unavailable in the app.',
      });

      Object? error;
      try {
        await service.executeAdminAccess({
          'action': 'add_admin',
          'email': 'a@b.c',
        });
      } catch (e) {
        error = e;
      }

      expect(
        error,
        isA<AppwriteException>()
            .having((e) => e.code, 'code', 501)
            .having((e) => e.type, 'type', adminAccessUnavailableType),
      );
      expect(
        adminAccessErrorMessage(error!),
        'Adding admins is unavailable in the app.',
      );
    });

    test('a non-owner remove shows the Worker explanation', () {
      final error = AppwriteException(
        'Your Appwrite account needs the owner role on the admin team for this action.',
        403,
        'admin_access_failed',
      );
      expect(adminAccessErrorMessage(error), contains('owner role'));
    });
  });

  group('Admin dashboards read the Worker', () {
    test('dashboard metrics bucket D1 activity rows', () async {
      final now = DateTime.now().toUtc();
      final api = _FakeDashboardApi()
        ..activity = {
          'lessons': [
            {
              'id': 'l1',
              r'$createdAt': now.toIso8601String(),
              r'$updatedAt': now.toIso8601String(),
              'titleLatin': 'Greetings',
            },
          ],
          'words': [
            {
              'id': 'w1',
              r'$createdAt': now.toIso8601String(),
              'wordLatin': 'dak',
            },
          ],
        };
      final container = ProviderContainer(
        overrides: [adminDashboardApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final metrics = await container.read(dashboardMetricsProvider.future);

      expect(metrics.lessonsSeries.last, 1);
      expect(metrics.vocabularySeries.last, 1);
      expect(
        metrics.recentActivity.map((a) => a.subtitle),
        containsAll(['Greetings', 'dak']),
      );
    });

    test('analytics snapshot uses the Worker rollups and actor-days', () async {
      final today = DateTime.now().toUtc();
      final key = formatDateKey(
        DateTime.utc(today.year, today.month, today.day),
      );
      final api = _FakeDashboardApi()
        ..analyticsData = AdminAnalyticsData(
          rollups: [
            {
              'dateKey': key,
              'eventName': 'lesson_completed',
              'totalEvents': 3,
              'uniqueUsers': 2,
              'sourceBreakdown': {'home': 2, 'app': 1},
              'platformBreakdown': {'android': 3},
            },
          ],
          events: [
            for (var i = 0; i < 1200; i++) {'dateKey': key, 'userId': 'u$i'},
          ],
          eventsTruncated: false,
        );
      final container = ProviderContainer(
        overrides: [adminDashboardApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(
        adminAnalyticsSnapshotProvider.future,
      );

      expect(api.analyticsCalls.single.$2, key);
      expect(snapshot.dau, 1200);
      expect(snapshot.eventTotals['lesson_completed'], 3);
      expect(snapshot.platformTotals['android'], 3);
      // A complete actor-day list is not "sampled" just because it is big.
      expect(snapshot.isSampled, isFalse);
      expect(snapshot.completeness, AnalyticsDataCompleteness.complete);
    });

    test('gamification metric ids map to their labels', () {
      final labelled = labelGamificationMetrics({
        'lessonsCompleted': 7,
        'publishedCulturalNotes': 2,
      });
      expect(labelled['Lessons completed'], 7);
      expect(labelled['Published cultural notes'], 2);
      expect(labelled['Unlocked badges'], 0);
      expect(labelled.length, gamificationMetricLabels.length);
    });
  });

  group('Review queue on the Worker', () {
    test('reviewContent actions POST to /admin/review/queue', () async {
      final requests = <http.Request>[];
      final container = ProviderContainer(
        overrides: [
          appwriteFunctionsServiceProvider.overrideWithValue(
            AppwriteFunctionsService(
              httpClient: MockClient((request) async {
                requests.add(request);
                final action = jsonDecode(request.body)['action'];
                return http.Response(
                  jsonEncode({
                    'success': true,
                    'data': action == 'list_audio'
                        ? {
                            'kind': 'audio',
                            'total': 1,
                            'documents': [
                              {
                                'id': 't1',
                                'audioUrl': 'https://x/a.mp3',
                                'generationStatus': 'completed',
                                'reviewStatus': 'needsReview',
                              },
                            ],
                          }
                        : {
                            'decision': 'approved',
                            'requested': 1,
                            'updated': 1,
                            'failed': 0,
                            'results': [
                              {'id': 't1', 'ok': true},
                            ],
                          },
                  }),
                  200,
                );
              }),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final client = container.read(adminReviewApiClientProvider);

      final page = await client.listAudioTracks();
      final result = await client.approveAudio(['t1']);

      expect(requests.map((r) => r.method), ['POST', 'POST']);
      expect(
        requests.map((r) => r.url.path),
        everyElement('/api/v1/admin/review/queue'),
      );
      expect(page.tracks.single.isApprovable, isTrue);
      expect(result.updated, 1);
      expect(jsonDecode(requests.last.body), {
        'action': 'approve_audio',
        'ids': ['t1'],
      });
    });
  });
}
