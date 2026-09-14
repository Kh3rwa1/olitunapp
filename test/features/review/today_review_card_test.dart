import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/presentation/today_review_card.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TodayReviewCard()),
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

  testWidgets('returns SizedBox.shrink when due is 0', (tester) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [
          dueReviewCountProvider.overrideWith((ref) => 0),
          lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_1'),
          userStatsProvider.overrideWith(() => _MockUserStats(const {})),
          mistakeProvider.overrideWith(() => _MockMistakes([])),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(TodayReviewCard), findsOneWidget);
    expect(find.text("TODAY'S REVIEW"), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
    'returns SizedBox.shrink when due > 0 but no incomplete lesson and no mistakes',
    (tester) async {
      await tester.pumpWidget(
        _host(
          prefs: prefs,
          overrides: [
            dueReviewCountProvider.overrideWith((ref) => 5),
            lastOpenedLessonIdProvider.overrideWith((ref) => null),
            userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
            mistakeProvider.overrideWith(() => _MockMistakes([])),
          ],
        ),
      );
      await tester.pump();

      expect(find.text("TODAY'S REVIEW"), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    },
  );

  testWidgets('renders review card when due > 0 and user left a lesson', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        prefs: prefs,
        overrides: [
          dueReviewCountProvider.overrideWith((ref) => 3),
          lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_incomplete'),
          userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
          mistakeProvider.overrideWith(() => _MockMistakes([])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('3 reviews due'), findsOneWidget);
    expect(find.text('Start review'), findsOneWidget);
  });

  testWidgets('renders review card when due > 0 and user has quiz mistakes', (
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
          dueReviewCountProvider.overrideWith((ref) => 2),
          lastOpenedLessonIdProvider.overrideWith((ref) => null),
          userStatsProvider.overrideWith(() => _MockUserStats({'lesson_1'})),
          mistakeProvider.overrideWith(() => _MockMistakes([mistake])),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S REVIEW"), findsOneWidget);
    expect(find.text('2 reviews due'), findsOneWidget);
    expect(find.text('Start review'), findsOneWidget);
  });
}
