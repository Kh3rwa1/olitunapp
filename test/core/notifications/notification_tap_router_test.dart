import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/app/router/app_router.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:itun/core/notifications/notification_tap_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('routeForNotificationPayload maps every payload', () {
    expect(routeForNotificationPayload('review'), '/review');
    expect(routeForNotificationPayload('daily'), '/');
    expect(routeForNotificationPayload('practice'), '/practice/daily');
    expect(routeForNotificationPayload('unknown'), isNull);
    expect(routeForNotificationPayload(null), isNull);
  });

  test('payload constants match the router contract', () {
    expect(NotificationService.reviewNotificationPayload, 'review');
    expect(NotificationService.dailyNotificationPayload, 'daily');
    expect(NotificationService.practiceNotificationPayload, 'practice');
  });

  testWidgets('a tap navigates and logs notification_opened', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final logged = <Map<String, dynamic>>[];
    final analytics = LearningAnalyticsService(
      prefs: prefs,
      remoteWriter: (_, payload) async => logged.add(payload),
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/review', builder: (_, _) => const Text('review')),
        GoRoute(
          path: '/practice/daily',
          builder: (_, _) => const Text('practice'),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    container.read(notificationTapRouterProvider);
    expect(NotificationService.onNotificationTap, isNotNull);

    NotificationService.onNotificationTap!('review');
    await tester.pumpAndSettle();
    expect(find.text('review'), findsOneWidget);

    NotificationService.onNotificationTap!('practice');
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);

    NotificationService.onNotificationTap!('daily');
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    // Unknown payloads are logged but do not navigate.
    NotificationService.onNotificationTap!('bogus');
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    final opened = logged
        .where((e) => e['eventName'] == notificationOpenedEvent)
        .toList();
    expect(opened.length, 4);
    expect(opened.first['source'], 'notification');
    expect(opened.first['metadata'], contains('review'));

    container.dispose();
    expect(NotificationService.onNotificationTap, isNull);
  });
}
