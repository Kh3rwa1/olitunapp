import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/presentation/today_review_card.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAnalyticsService extends LearningAnalyticsService {
  final recordedEvents = <Map<String, dynamic>>[];

  _RecordingAnalyticsService(SharedPreferences prefs)
    : super(prefs: prefs, remoteWriter: (_, _) async {});

  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    String? learnerLevel,
    String? scriptMode,
    Map<String, dynamic>? metadata,
  }) async {
    recordedEvents.add({
      'eventName': eventName,
      'source': source,
      'metadata': metadata,
    });
  }
}

class _MockUserStats extends UserStatsNotifier {
  final Set<String> _completed;
  _MockUserStats(this._completed);

  @override
  AsyncValue<UserStatsEntity> build() => AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: _completed,
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 10,
      lastActiveDate: '',
      currentStreak: 1,
      totalStars: 5,
    ),
  );
}

class _MockMistakes extends MistakeNotifier {
  final List<MistakeItem> _items;
  _MockMistakes(this._items);

  @override
  List<MistakeItem> build() => _items;
}

Widget _host({
  required List<Override> overrides,
  required SharedPreferences prefs,
  GoRouter? router,
}) {
  final effectiveRouter =
      router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: TodayReviewCard()),
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) =>
                const Scaffold(body: Text('Review Session Screen')),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      corpusIdentityMapProvider.overrideWith(
        (ref) async => ReviewCorpusIdentityMap.empty(),
      ),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: effectiveRouter,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('returns SizedBox.shrink when due count is 0', (tester) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [dueReviewCountProvider.overrideWith((ref) => 0)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodayReviewCard), findsOneWidget);
    expect(find.text("TODAY'S REVIEW"), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
    'displays card when due > 0 even with no incomplete lesson and no mistakes',
    (tester) async {
      await tester.pumpWidget(
        _host(
          prefs: prefs,
          overrides: [
            dueReviewCountProvider.overrideWith((ref) => 3),
            lastOpenedLessonIdProvider.overrideWith((ref) => null),
            userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
            mistakeProvider.overrideWith(() => _MockMistakes([])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S REVIEW"), findsOneWidget);
      expect(find.text('3 reviews due'), findsOneWidget);
      expect(find.text('Start review'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    },
  );

  testWidgets('displays card when due > 0 and user has incomplete lesson', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [
          dueReviewCountProvider.overrideWith((ref) => 2),
          lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_2'),
          userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
          mistakeProvider.overrideWith(() => _MockMistakes([])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('2 reviews due'), findsOneWidget);
    expect(find.text('Start review'), findsOneWidget);
  });

  testWidgets('displays card when due > 0 and user has mistakes', (
    tester,
  ) async {
    final mistake = MistakeItem(
      quizId: 'q1',
      questionIndex: 0,
      question: QuizQuestion(promptOlChiki: 'test', optionsOlChiki: ['a', 'b']),
      addedAt: '2026-09-14',
    );

    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [
          dueReviewCountProvider.overrideWith((ref) => 4),
          lastOpenedLessonIdProvider.overrideWith((ref) => null),
          userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
          mistakeProvider.overrideWith(() => _MockMistakes([mistake])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('4 reviews due'), findsOneWidget);
    expect(find.text('Start review'), findsOneWidget);
  });

  testWidgets('uses singular localized copy when 1 review is due', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [dueReviewCountProvider.overrideWith((ref) => 1)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('1 review due'), findsOneWidget);
    expect(find.text('Start review'), findsOneWidget);
  });

  testWidgets('uses plural localized copy when multiple reviews are due', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [dueReviewCountProvider.overrideWith((ref) => 5)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('5 reviews due'), findsOneWidget);
  });

  testWidgets('displays correct due count and duration estimate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [dueReviewCountProvider.overrideWith((ref) => 12)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 reviews due'), findsOneWidget);
    // 12 items * 40s = 480s = 8 min
    expect(
      find.text('~8 min · from lessons you already started'),
      findsOneWidget,
    );
  });

  testWidgets('tapping Start Review navigates to /review and emits analytics', (
    tester,
  ) async {
    final analytics = _RecordingAnalyticsService(prefs);

    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [
          dueReviewCountProvider.overrideWith((ref) => 3),
          learningAnalyticsServiceProvider.overrideWithValue(analytics),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start review'), findsOneWidget);
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Verify navigation reached /review
    expect(find.text('Review Session Screen'), findsOneWidget);

    // Verify analytics tracked event
    expect(analytics.recordedEvents, hasLength(1));
    final event = analytics.recordedEvents.first;
    expect(event['eventName'], LearningAnalyticsEvents.todayReviewTapped);
    expect(event['source'], 'today_review_card');
    expect(event['metadata'], {'dueCount': 3, 'minutes': 2});
  });

  testWidgets(
    'loading state does not show false zero-state (hides card during load)',
    (tester) async {
      await tester.pumpWidget(
        _host(
          prefs: prefs,
          overrides: [
            reviewStoreProvider.overrideWith(_LoadingReviewStoreNotifier.new),
            dueReviewCountProvider.overrideWith((ref) => 0),
          ],
        ),
      );
      // Pump without settling so provider stays in loading state
      await tester.pump();

      expect(find.byType(TodayReviewCard), findsOneWidget);
      expect(find.text("TODAY'S REVIEW"), findsNothing);
      expect(find.text('0 reviews due'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    },
  );
}

class _LoadingReviewStoreNotifier extends ReviewStoreNotifier {
  @override
  Future<ReviewStore> build() => Completer<ReviewStore>().future;
}
