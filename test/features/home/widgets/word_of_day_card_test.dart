import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/home/presentation/widgets/word_of_day_card.dart';
import 'package:itun/features/practice/daily/presentation/providers/daily_practice_providers.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

WordModel _word(String id, {int order = 0, String? audio}) => WordModel(
  id: id,
  wordOlChiki: 'ᱚ$id',
  wordLatin: 'latin-$id',
  meaning: 'meaning-$id',
  order: order,
  audioUrl: audio,
);

void main() {
  final now = DateTime(2026, 11, 10, 9);

  testWidgets('renders the deterministic word and seeds daily practice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final words = [_word('a'), _word('b', order: 1), _word('c', order: 2)];
    final expected = words.firstWhere(
      (w) => w.id == (['a', 'b', 'c']..sort())[_dayIndex(now, 3)],
    );
    late ProviderContainer container;
    await tester.pumpWidget(
      routerHost(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const WordOfDayCard();
          },
        ),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(prefs),
          ),
          learnerWordsProvider.overrideWithValue(AsyncValue.data(words)),
          teachingLanguageProvider.overrideWith((ref) => 'en'),
          todayActivityClockProvider.overrideWithValue(() => now),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WORD OF THE DAY'), findsOneWidget);
    expect(find.text(expected.wordOlChiki), findsOneWidget);
    expect(find.textContaining(expected.meaning), findsOneWidget);
    // No audio URL → no play button.
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

    await tester.tap(find.text('Practice this word'));
    await tester.pumpAndSettle();

    expect(find.text('route-placeholder'), findsOneWidget);
    expect(container.read(dailyPracticeSeedWordProvider), expected.id);
  });

  testWidgets('hidden while the corpus is loading or empty', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      routerHost(
        child: const WordOfDayCard(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(prefs),
          ),
          learnerWordsProvider.overrideWithValue(const AsyncValue.loading()),
          teachingLanguageProvider.overrideWith((ref) => 'en'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('WORD OF THE DAY'), findsNothing);
  });

  testWidgets('shows the play button when the word has audio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      routerHost(
        child: const WordOfDayCard(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(prefs),
          ),
          learnerWordsProvider.overrideWithValue(
            AsyncValue.data([_word('solo', audio: 'https://x/a.mp3')]),
          ),
          teachingLanguageProvider.overrideWith((ref) => 'hi'),
          todayActivityClockProvider.overrideWithValue(() => now),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play pronunciation'), findsOneWidget);
  });
}

int _dayIndex(DateTime day, int length) {
  final local = DateTime(day.year, day.month, day.day);
  return local.difference(DateTime(1970)).inDays % length;
}
