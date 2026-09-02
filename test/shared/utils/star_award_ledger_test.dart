import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/utils/star_award_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anti-farming ledger: each content item pays stars at most once per
/// calendar day; previous days are pruned so storage stays bounded.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  StarAwardLedger ledger() => StarAwardLedger(() => prefs);

  test('allows the first award and blocks repeats within the same day', () {
    expect(ledger().canAward(kind: 'typing', id: 'word_1'), isTrue);

    ledger().markAwarded(kind: 'typing', id: 'word_1');

    expect(ledger().canAward(kind: 'typing', id: 'word_1'), isFalse);
  });

  test('different kinds and ids are tracked independently', () {
    ledger().markAwarded(kind: 'typing', id: 'word_1');

    expect(ledger().canAward(kind: 'typing', id: 'word_2'), isTrue);
    expect(ledger().canAward(kind: 'trace', id: 'word_1'), isTrue);
  });

  test('a different date key resets eligibility (day rollover)', () {
    ledger().markAwarded(kind: 'trace', id: 'ᱟ');

    // Simulate the ledger surviving to the next day: entries are stored
    // under today's date key; a fresh day has no entries for it.
    final stored = prefs.getString('star_award_ledger_v1')!;
    expect(stored, contains('trace:ᱟ'));

    // Rewind the stored date to yesterday — today's lookup finds nothing.
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yKey =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final rolled = stored.replaceFirst(
      RegExp(r'"(\d{4}-\d{2}-\d{2})"'),
      '"$yKey"',
    );
    prefs.setString('star_award_ledger_v1', rolled);

    expect(ledger().canAward(kind: 'trace', id: 'ᱟ'), isTrue);
  });

  test('prunes previous days on write, keeping storage bounded', () {
    // Seed with a stale day + entries.
    prefs.setString(
      'star_award_ledger_v1',
      '{"2020-01-01":["trace:᱑","trace:᱒"]}',
    );

    ledger().markAwarded(kind: 'trace', id: '᱓');

    final stored = prefs.getString('star_award_ledger_v1')!;
    expect(stored, isNot(contains('2020-01-01')));
    expect(stored, isNot(contains('trace:᱑')));
    expect(ledger().canAward(kind: 'trace', id: '᱑'), isTrue);
  });

  test('corrupt ledger JSON is treated as empty, not thrown', () {
    prefs.setString('star_award_ledger_v1', '{not json');

    expect(ledger().canAward(kind: 'typing', id: 'any'), isTrue);
  });
}
