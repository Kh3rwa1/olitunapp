import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import '../storage/hive_service.dart';
import 'analytics_service.dart';

/// Logs `app_open`: once per cold start and again whenever the app returns
/// to the foreground after [resumeGap] in the background. `app_open` is the
/// daily-active denominator; `days_since_last_open` makes lapse length
/// measurable without a server-side user table.
class AppOpenTracker with WidgetsBindingObserver {
  AppOpenTracker({
    required SharedPreferences prefs,
    required LearningAnalyticsService analytics,
    DateTime Function()? now,
    this.resumeGap = const Duration(minutes: 30),
  }) : _prefs = prefs,
       _analytics = analytics,
       _now = now ?? DateTime.now;

  /// ISO-8601 local timestamp of the previous open.
  static const lastOpenAtKey = 'last_app_open_at';

  final SharedPreferences _prefs;
  final LearningAnalyticsService _analytics;
  final DateTime Function() _now;
  final Duration resumeGap;

  DateTime? _pausedAt;
  bool _coldStartLogged = false;

  /// Whether the cold-start open has been logged for this process.
  bool get coldStartLogged => _coldStartLogged;

  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  /// Logs the cold-start open exactly once per process. Returns the event
  /// metadata, or null when it was already logged.
  Future<Map<String, Object>?> trackColdStart() async {
    if (_coldStartLogged) return null;
    _coldStartLogged = true;
    return _logOpen(cold: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(handleLifecycle(state));
  }

  /// Background for [resumeGap] or longer, then foreground, counts as a new
  /// open. Returns the logged metadata, or null when nothing was logged.
  Future<Map<String, Object>?> handleLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= _now();
      return Future.value();
    }
    if (state != AppLifecycleState.resumed) return Future.value();
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return Future.value();
    if (_now().difference(pausedAt) < resumeGap) return Future.value();
    return _logOpen(cold: false);
  }

  Future<Map<String, Object>> _logOpen({required bool cold}) async {
    final now = _now();
    final previous = DateTime.tryParse(_prefs.getString(lastOpenAtKey) ?? '');
    final daysSince = previous == null ? null : daysBetween(previous, now);
    try {
      await _prefs.setString(lastOpenAtKey, now.toIso8601String());
    } catch (e) {
      AppLogger.debug('AppOpenTracker: could not store last open: $e');
    }
    final metadata = <String, Object>{
      'cold': cold,
      'days_since_last_open': ?daysSince,
    };
    unawaited(
      _analytics
          .track(
            LearningAnalyticsEvents.appOpen,
            source: 'lifecycle',
            metadata: metadata,
          )
          .catchError((Object e) {
            AppLogger.debug('AppOpenTracker: app_open not logged: $e');
          }),
    );
    return metadata;
  }

  /// Whole calendar days between two local timestamps (never negative).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    final days = b.difference(a).inDays;
    return days < 0 ? 0 : days;
  }
}

/// Alive for the app's lifetime (watched from the root experience scope).
/// Null when prefs are not provided, as in headless widget tests.
final appOpenTrackerProvider = Provider<AppOpenTracker?>((ref) {
  final SharedPreferences prefs;
  final LearningAnalyticsService analytics;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
    analytics = ref.watch(learningAnalyticsServiceProvider);
  } catch (_) {
    return null;
  }
  final tracker = AppOpenTracker(prefs: prefs, analytics: analytics)..attach();
  unawaited(tracker.trackColdStart());
  ref.onDispose(tracker.detach);
  return tracker;
});
