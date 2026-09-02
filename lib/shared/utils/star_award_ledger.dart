import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Once-per-day star award guard (anti-farming).
///
/// Practice surfaces award stars on completion; because screens are
/// re-enterable, the same completion could be replayed indefinitely to
/// farm stars. This ledger records `kind:id` pairs per local date key and
/// prunes previous days on write, so each content item pays at most once
/// per calendar day while keeping the storage footprint bounded to a
/// single prefs entry.
class StarAwardLedger {
  /// Takes a prefs getter so both Riverpod `Ref` and `WidgetRef` call
  /// sites can supply it: `StarAwardLedger(() => ref.read(prefsProvider))`.
  StarAwardLedger(this._prefs);

  final SharedPreferences Function() _prefs;

  static const String _prefKey = 'star_award_ledger_v1';

  String _dateKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, Set<String>> _read() {
    final raw = _prefs().getString(_prefKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (date, ids) => MapEntry(date, Set<String>.from(ids as List)),
      );
    } catch (_) {
      return {};
    }
  }

  void _write(Map<String, Set<String>> ledger) {
    final today = _dateKey();
    // Keep only today's entries — yesterday's awards are irrelevant.
    final pruned = {today: ledger[today] ?? <String>{}};
    final encodable = pruned.map((date, ids) => MapEntry(date, ids.toList()));
    _prefs().setString(_prefKey, jsonEncode(encodable));
  }

  /// Whether `kind:id` has not been awarded today.
  bool canAward({required String kind, required String id}) {
    final ledger = _read();
    return !(ledger[_dateKey()]?.contains('$kind:$id') ?? false);
  }

  /// Records `kind:id` as awarded today.
  void markAwarded({required String kind, required String id}) {
    final ledger = _read();
    final today = _dateKey();
    final entries = ledger[today] ?? <String>{};
    entries.add('$kind:$id');
    _write({today: entries});
  }
}
