// Notification tap routing: review payloads deep-link to Today's Review.
//
// Lives outside NotificationService to avoid an import cycle
// (app_router -> screens -> notification_service). Watched once at the app
// root; cold-start taps (app killed) land on Home, whose Today's Review
// card carries the same action — acceptable degradation, no fake routing.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../logging/app_logger.dart';
import 'notification_service.dart';

final notificationTapRouterProvider = Provider<void>((ref) {
  NotificationService.onNotificationTap = (payload) {
    if (payload != NotificationService.reviewNotificationPayload) return;
    try {
      ref.read(routerProvider).go('/review');
    } catch (e) {
      AppLogger.debug('NotificationTapRouter: navigation failed: $e');
    }
  };
  ref.onDispose(() {
    NotificationService.onNotificationTap = null;
  });
});
