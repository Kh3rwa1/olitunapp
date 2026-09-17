// Account-scoped mistake persistence: keys, lists, legacy claim, and
// guest migration. Pure `SharedPreferences` helpers (no Riverpod) so the
// notifier stays focused on queue derivation and backend sync.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/account_scope.dart';
import '../../../../core/logging/app_logger.dart';
import 'mistake_item.dart';

// Legacy GLOBAL keys (unowned). Claimed once per proven owner into scoped
// keys; never read across accounts.
const String kLegacyPrefKey = 'user_mistakes_list';
const String kLegacyResolvedAuditKey = 'user_mistakes_resolved_audit_v1';
const String kLegacyClaimKey = 'user_mistakes_legacy_claim_v1';

String mistakeListKey(String suffix) => 'user_mistakes_list_$suffix';
String mistakeAuditKey(String suffix) =>
    'user_mistakes_resolved_audit_v1_$suffix';
String mistakeOutboxKey(String suffix) => 'user_mistakes_outbox_$suffix';

/// Owner suffix for all mistake storage: `guest`, `<userId>`, or
/// `account:guest` for the literal account id "guest" (never collides
/// with guest mode).
String mistakeOwnerSuffix(SharedPreferences prefs) {
  final scope = AccountScope.capture(prefs);
  if (scope.isGuest) return 'guest';
  final id = scope.userId;
  if (id == null || id.isEmpty) return 'guest';
  return id == 'guest' ? 'account:guest' : id;
}

List<MistakeItem> readMistakeList(SharedPreferences prefs, String key) {
  try {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } catch (_) {
    return [];
  }
}

/// One-time claim of legacy GLOBAL mistake keys into the current proven
/// owner's scoped keys. Runs only for known scopes; records a durable
/// claim marker so a second account never imports the same legacy data.
/// Unknown/corrupt scopes leave legacy keys untouched (fail closed).
Future<void> claimLegacyMistakes(SharedPreferences prefs, String suffix) async {
  final scope = AccountScope.capture(prefs);
  if (!scope.isKnown) return;
  if (prefs.getString(kLegacyClaimKey) != null) return;
  final hasLegacy =
      prefs.containsKey(kLegacyPrefKey) ||
      prefs.containsKey(kLegacyResolvedAuditKey);
  if (!hasLegacy) {
    await prefs.setString(
      kLegacyClaimKey,
      jsonEncode({'owner': suffix, 'at': DateTime.now().toIso8601String()}),
    );
    return;
  }
  try {
    final legacyRaw = prefs.getString(kLegacyPrefKey);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(legacyRaw);
      final legacy = decoded
          .map((item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final current = readMistakeList(prefs, mistakeListKey(suffix));
      final merged = <String, MistakeItem>{
        for (final item in current) '${item.quizId}:${item.questionId}': item,
        for (final item in legacy)
          if (!(item.isResolved)) '${item.quizId}:${item.questionId}': item,
      };
      await prefs.setString(
        mistakeListKey(suffix),
        jsonEncode(merged.values.map((e) => e.toJson()).toList()),
      );
    }
    final legacyAuditRaw = prefs.getString(kLegacyResolvedAuditKey);
    if (legacyAuditRaw != null && legacyAuditRaw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(legacyAuditRaw);
      final legacyAudit = decoded
          .map((item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final currentAudit = readMistakeList(prefs, mistakeAuditKey(suffix));
      final merged = <String, MistakeItem>{
        for (final item in currentAudit)
          '${item.quizId}:${item.questionId}': item,
        for (final item in legacyAudit)
          '${item.quizId}:${item.questionId}': item,
      };
      await prefs.setString(
        mistakeAuditKey(suffix),
        jsonEncode(merged.values.map((e) => e.toJson()).toList()),
      );
    }
  } catch (e) {
    AppLogger.debug('MistakeNotifier: legacy claim decode failed: $e');
  }
  await prefs.remove(kLegacyPrefKey);
  await prefs.remove(kLegacyResolvedAuditKey);
  await prefs.setString(
    kLegacyClaimKey,
    jsonEncode({'owner': suffix, 'at': DateTime.now().toIso8601String()}),
  );
}

/// Guest -> account mistake migration (union semantics: idempotent reruns
/// converge; never duplicates events). Returns true when guest state was
/// merged. The caller reloads its in-memory queue afterwards.
Future<bool> mergeGuestMistakes(
  SharedPreferences prefs,
  String accountSuffix,
) async {
  final scope = AccountScope.capture(prefs);
  if (!scope.isKnown || scope.isGuest) return false;
  try {
    final guestList = readMistakeList(prefs, mistakeListKey('guest'));
    final guestAudit = readMistakeList(prefs, mistakeAuditKey('guest'));
    if (guestList.isEmpty && guestAudit.isEmpty) return false;
    final accountList = readMistakeList(prefs, mistakeListKey(accountSuffix));
    final merged = <String, MistakeItem>{
      for (final item in accountList) '${item.quizId}:${item.questionId}': item,
      for (final item in guestList)
        if (!item.isResolved) '${item.quizId}:${item.questionId}': item,
    };
    await prefs.setString(
      mistakeListKey(accountSuffix),
      jsonEncode(merged.values.map((e) => e.toJson()).toList()),
    );
    final accountAudit = readMistakeList(prefs, mistakeAuditKey(accountSuffix));
    final mergedAudit = <String, MistakeItem>{
      for (final item in accountAudit)
        '${item.quizId}:${item.questionId}': item,
      for (final item in guestAudit) '${item.quizId}:${item.questionId}': item,
    };
    await prefs.setString(
      mistakeAuditKey(accountSuffix),
      jsonEncode(mergedAudit.values.map((e) => e.toJson()).toList()),
    );
    await prefs.remove(mistakeListKey('guest'));
    await prefs.remove(mistakeAuditKey('guest'));
    return true;
  } catch (e) {
    AppLogger.debug('Mistake storage: guest migration failed: $e');
    return false;
  }
}
