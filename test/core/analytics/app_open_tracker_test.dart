import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/analytics/app_open_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late List<Map<String, dynamic>> writes;
  late DateTime now;
  var ids = 0;

  LearningAnalyticsService analytics() => LearningAnalyticsService(
    prefs: prefs,
    idFactory: () => 'id_${++ids}',
    now: () => now,
    remoteWriter: (_, payload) async => writes.add(payload),
  );

  List<Map<String, dynamic>> opens() =>
      writes.where((w) => w['eventName'] == 'app_open').toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    writes = [];
    ids = 0;
    now = DateTime(2026, 11, 10, 9);
  });

  test('cold start logs app_open once with no lapse on first launch', () async {
    final tracker = AppOpenTracker(
      prefs: prefs,
      analytics: analytics(),
      now: () => now,
    );

    final first = await tracker.trackColdStart();
    await Future<void>.delayed(Duration.zero);
    expect(first, {'cold': true});
    expect(tracker.coldStartLogged, isTrue);
    expect(opens(), hasLength(1));
    expect(
      prefs.getString(AppOpenTracker.lastOpenAtKey),
      now.toIso8601String(),
    );

    expect(await tracker.trackColdStart(), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(opens(), hasLength(1));
  });

  test('days_since_last_open measures the lapse in calendar days', () async {
    await prefs.setString(
      AppOpenTracker.lastOpenAtKey,
      DateTime(2026, 11, 7, 23, 50).toIso8601String(),
    );
    final tracker = AppOpenTracker(
      prefs: prefs,
      analytics: analytics(),
      now: () => now,
    );

    final metadata = await tracker.trackColdStart();
    expect(metadata, {'cold': true, 'days_since_last_open': 3});
  });

  test(
    'resume after the gap logs a warm open; a short pause does not',
    () async {
      final tracker = AppOpenTracker(
        prefs: prefs,
        analytics: analytics(),
        now: () => now,
      );
      await tracker.trackColdStart();

      await tracker.handleLifecycle(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      expect(await tracker.handleLifecycle(AppLifecycleState.resumed), isNull);

      await tracker.handleLifecycle(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 31));
      final warm = await tracker.handleLifecycle(AppLifecycleState.resumed);
      expect(warm, {'cold': false, 'days_since_last_open': 0});

      // Resuming without a recorded pause is not an open.
      expect(await tracker.handleLifecycle(AppLifecycleState.resumed), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(opens(), hasLength(2));
    },
  );

  test('daysBetween ignores time of day and never goes negative', () {
    expect(
      AppOpenTracker.daysBetween(
        DateTime(2026, 1, 1, 23, 59),
        DateTime(2026, 1, 2).add(const Duration(minutes: 1)),
      ),
      1,
    );
    expect(
      AppOpenTracker.daysBetween(DateTime(2026, 1, 5), DateTime(2026, 1, 2)),
      0,
    );
  });
}
