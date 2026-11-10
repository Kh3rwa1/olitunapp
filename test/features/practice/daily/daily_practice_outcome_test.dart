import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_builder.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_outcome.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/presentation/review_exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReviewCard _card(String id) => ReviewCard(
  itemId: id,
  itemType: ReviewItemType.word,
  kind: ReviewPromptKind.olChikiToMeaning,
  promptOlChiki: 'ᱚ',
  promptLatin: '',
  promptMeaning: '',
  audioUrl: '',
  options: const ['a', 'b'],
);

void main() {
  group('DailyPracticeOutcome', () {
    test('stars per correct, minutes rounded up, unique seen ids', () {
      final outcome = DailyPracticeOutcome.from([
        (card: _card('w1'), correct: true),
        (card: _card('w2'), correct: false),
        (card: _card('w1'), correct: true),
        (card: _card('$letterItemIdPrefixᱚ'), correct: true),
      ], elapsed: const Duration(minutes: 2, seconds: 1));
      expect(outcome.stars, 3 * dailyPracticeStarsPerCorrect);
      expect(outcome.minutes, 3);
      expect(outcome.correctCount, 3);
      expect(outcome.total, 4);
      expect(outcome.seenIds, ['w1', 'w2', '$letterItemIdPrefixᱚ']);
      expect(outcome.reviewStoreIds, ['w1', 'w2']);
    });

    test('a finished session counts at least one minute', () {
      final outcome = DailyPracticeOutcome.from([
        (card: _card('w1'), correct: false),
      ], elapsed: const Duration(seconds: 20));
      expect(outcome.minutes, 1);
      expect(outcome.stars, 0);
    });

    test('nothing answered yields nothing', () {
      final outcome = DailyPracticeOutcome.from(
        const [],
        elapsed: const Duration(minutes: 5),
      );
      expect(outcome.minutes, 0);
      expect(outcome.stars, 0);
      expect(outcome.seenIds, isEmpty);
    });
  });

  group('RecentPracticeLog', () {
    test('keeps newest ids last, de-duplicated, capped at 60', () async {
      SharedPreferences.setMockInitialValues({});
      final log = RecentPracticeLog(await SharedPreferences.getInstance());
      expect(log.ids(), isEmpty);

      await log.markSeen(['a', 'b']);
      await log.markSeen(['b', 'c']);
      expect(log.ids(), {'a', 'b', 'c'});

      await log.markSeen([for (var i = 0; i < 70; i++) 'x$i']);
      final ids = log.ids();
      expect(ids.length, RecentPracticeLog.limit);
      expect(ids, isNot(contains('a')));
      expect(ids, contains('x69'));

      await log.clear();
      expect(log.ids(), isEmpty);
    });
  });
}
