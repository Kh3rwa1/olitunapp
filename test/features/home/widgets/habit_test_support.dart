// Shared fakes for the Home habit-loop widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingAnalyticsService extends LearningAnalyticsService {
  RecordingAnalyticsService(SharedPreferences prefs)
    : super(prefs: prefs, remoteWriter: (_, _) async {});

  final events = <({String name, String? source, Map<String, dynamic> meta})>[];

  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {
    events.add((name: eventName, source: source, meta: metadata));
  }

  List<String> get names => events.map((e) => e.name).toList();
}

String dateKey(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

UserStatsEntity statsWith({
  int streak = 0,
  Set<String> practiceDates = const {},
  String lastActiveDate = '',
  Set<String> completedLessons = const {},
  int totalStars = 0,
}) => UserStatsEntity(
  practicedLetters: const {},
  completedLessons: completedLessons,
  quizHistory: const {},
  categoryMastery: const {},
  totalLearningMinutes: 0,
  lastActiveDate: lastActiveDate,
  currentStreak: streak,
  totalStars: totalStars,
  practiceDates: practiceDates,
);

class FixedStatsNotifier extends UserStatsNotifier {
  FixedStatsNotifier(this._stats);
  final UserStatsEntity _stats;

  @override
  AsyncValue<UserStatsEntity> build() => AsyncValue.data(_stats);
}

/// Hosts [child] at `/` with a placeholder page for [extraRoute], so taps
/// that `context.push` can be asserted via the placeholder text.
Widget routerHost({
  required Widget child,
  required List<Override> overrides,
  String extraRoute = '/practice/daily',
  String placeholder = 'route-placeholder',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: extraRoute,
        builder: (context, state) => Scaffold(body: Text(placeholder)),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const Scaffold(body: Text('profile-placeholder')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}
