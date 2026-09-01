import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'breadcrumb_tracker.dart';
import 'crash_reporting.dart';

class AppObservability {
  AppObservability._();

  static final BreadcrumbTracker tracker = BreadcrumbTracker.instance;

  static void recordError(
    Object error,
    StackTrace? stack, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    tracker.add(
      category: context ?? 'error',
      message: error.toString(),
      level: BreadcrumbLevel.error,
      data: metadata,
    );

    AppLogger.error(
      'Observability: ${context != null ? "[$context] " : ""}$error',
      fields: {'stack': stack?.toString()},
    );

    CrashReporting.recordError(error, stack);
  }

  static void recordNavigation(String from, String to) {
    tracker.add(
      category: 'navigation',
      message: 'Navigate from $from to $to',
      data: {'from': from, 'to': to},
    );
    CrashReporting.addNavigationBreadcrumb(from, to);
  }

  static void recordInteraction(String component, String action) {
    tracker.add(
      category: 'interaction',
      message: '$action on $component',
      data: {'component': component, 'action': action},
    );
    CrashReporting.addUIBreadcrumb(element: component, action: action);
  }

  static void recordAudioEvent(String event, {String? trackId, String? error}) {
    tracker.add(
      category: 'audio',
      message: error != null ? '$event: $error' : event,
      level: error != null ? BreadcrumbLevel.error : BreadcrumbLevel.info,
      data: {'event': event, 'trackId': ?trackId, 'error': ?error},
    );
    CrashReporting.addAudioBreadcrumb(
      action: event,
      trackId: trackId,
      error: error,
    );
  }

  static String generateDiagnosticsPayload({Map<String, dynamic>? extraInfo}) {
    final report = <String, dynamic>{
      'app': 'Olitun',
      'generatedAt': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'debugMode': kDebugMode,
      if (extraInfo != null)
        'systemInfo': BreadcrumbTracker.sanitizeData(extraInfo),
      'recentBreadcrumbs': tracker
          .getRecent(25)
          .map((b) => b.toJson())
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }
}

/// Riverpod observer logging state changes and unhandled exceptions.
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Only trace AsyncError states
    if (newValue is AsyncError) {
      AppObservability.recordError(
        newValue.error,
        newValue.stackTrace,
        context: 'provider.${provider.name ?? provider.runtimeType}',
      );
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppObservability.recordError(
      error,
      stackTrace,
      context: 'provider.${provider.name ?? provider.runtimeType}',
    );
  }
}
