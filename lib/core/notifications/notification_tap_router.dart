// Notification tap routing by payload:
//   review   → Today's Review ('/review')
//   daily    → Home ('/')
//   practice → Daily Practice ('/practice/daily')
//
// Lives outside NotificationService to avoid an import cycle
// (app_router -> screens -> notification_service). Watched once at the app
// root; cold-start taps (app killed) land on Home, whose cards carry the
// same actions — acceptable degradation, no fake routing.
//
// Every tap is logged as `notification_opened` and skips the next app-open
// ad, so a learner answering a reminder is never greeted by an ad.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../ads/ad_service.dart';
import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import 'notification_service.dart';

/// Analytics event name for a reminder tap.
const String notificationOpenedEvent = 'notification_opened';

/// Route for a notification payload, or null for unknown payloads.
String? routeForNotificationPayload(String? payload) {
  switch (payload) {
    case NotificationService.reviewNotificationPayload:
      return '/review';
    case NotificationService.dailyNotificationPayload:
      return '/';
    case NotificationService.practiceNotificationPayload:
      return '/practice/daily';
    default:
      return null;
  }
}

final notificationTapRouterProvider = Provider<void>((ref) {
  NotificationService.onNotificationTap = (payload) {
    try {
      ref
          .read(adServiceProvider)
          .skipNextAppOpen(window: const Duration(seconds: 60));
    } catch (e) {
      AppLogger.debug('NotificationTapRouter: ad skip failed: $e');
    }
    try {
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            notificationOpenedEvent,
            source: 'notification',
            metadata: {'payload': payload ?? ''},
          );
    } catch (e) {
      AppLogger.debug('NotificationTapRouter: analytics failed: $e');
    }
    final route = routeForNotificationPayload(payload);
    if (route == null) return;
    try {
      ref.read(routerProvider).go(route);
    } catch (e) {
      AppLogger.debug('NotificationTapRouter: navigation failed: $e');
    }
  };
  ref.onDispose(() {
    NotificationService.onNotificationTap = null;
  });
});
