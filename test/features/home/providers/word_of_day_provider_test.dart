import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/home/presentation/providers/word_of_day_provider.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';

WordModel _word(String id, {int order = 0, bool active = true}) => WordModel(
  id: id,
  wordOlChiki: 'ᱚ$id',
  wordLatin: id,
  meaning: 'meaning $id',
  order: order,
  isActive: active,
);

void main() {
  group('pickWordOfDay', () {
    final words = [
      _word('c', order: 2),
      _word('a'),
      _word('b', order: 1),
      _word('hidden', order: -1, active: false),
    ];

    test('is deterministic for a day and rotates by day', () {
      final d1 = DateTime(2026, 11, 10, 9);
      final d1Later = DateTime(2026, 11, 10, 23, 59);
      final d2 = DateTime(2026, 11, 11);
      final pick1 = pickWordOfDay(words, d1)!;
      expect(pickWordOfDay(words, d1Later)!.id, pick1.id);
      expect(pickWordOfDay(words, d2)!.id, isNot(pick1.id));
    });

    test('cycles through every active word once per corpus length', () {
      final start = DateTime(2026);
      final ids = {
        for (var i = 0; i < 3; i++)
          pickWordOfDay(words, start.add(Duration(days: i)))!.id,
      };
      expect(ids, {'a', 'b', 'c'});
    });

    test('skips inactive words and handles an empty corpus', () {
      final start = DateTime(2026);
      for (var i = 0; i < 10; i++) {
        expect(
          pickWordOfDay(words, start.add(Duration(days: i)))!.id,
          isNot('hidden'),
        );
      }
      expect(pickWordOfDay(const [], start), isNull);
      expect(pickWordOfDay([_word('x', active: false)], start), isNull);
    });

    test('daysSinceEpoch uses the local date part only', () {
      expect(daysSinceEpoch(DateTime(1970, 1, 2, 23)), 1);
      expect(daysSinceEpoch(DateTime(1970, 1, 1, 0, 1)), 0);
    });
  });

  group('wordOfDayProvider', () {
    test('null while loading, a word once the corpus is there', () {
      final loading = ProviderContainer(
        overrides: [
          learnerWordsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
      );
      addTearDown(loading.dispose);
      expect(loading.read(wordOfDayProvider), isNull);

      final loaded = ProviderContainer(
        overrides: [
          learnerWordsProvider.overrideWithValue(
            AsyncValue.data([_word('a'), _word('b', order: 1)]),
          ),
          todayActivityClockProvider.overrideWithValue(
            () => DateTime(2026, 11, 10),
          ),
        ],
      );
      addTearDown(loaded.dispose);
      final word = loaded.read(wordOfDayProvider);
      expect(word, isNotNull);
      expect(
        word!.id,
        pickWordOfDay([
          _word('a'),
          _word('b', order: 1),
        ], DateTime(2026, 11, 10))!.id,
      );
    });
  });
}
