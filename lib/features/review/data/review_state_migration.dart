// Explicit guest to account review-state migration policy.
//
// When an unauthenticated guest learns items and then signs in, their accumulated
// memory progress must be safely merged into the authenticated account without
// losing learning evidence (recalls, typing successes, lapses, intervals), while
// guaranteeing zero cross-account leakage on logout and account switching.
//
// Hardened path: [migrateGuestToAccount] delegates to [ReviewMigrationEngine]
// (see review_migration_ledger.dart) whenever [prefs] and
// [destinationOwnerKey] are supplied — durable receipts, crash-safe resume,
// exactly-once deltas. Production callers MUST supply them. The prefs-less
// overload is a compatibility single-shot for tests and legacy call sites.

import 'package:shared_preferences/shared_preferences.dart';

import 'review_migration_engine.dart';
import 'review_migration_ledger.dart';
import 'review_store.dart';

export 'review_migration_engine.dart';
export 'review_migration_ledger.dart'
    show ReviewStateMigrationResult, MigrationLedger;

class ReviewStateMigrator {
  const ReviewStateMigrator._();

  /// Migrates guest SRS items into an authenticated user's store.
  ///
  /// Merge Policy (shared deterministic function
  /// [ReviewMigrationEngine.mergeGuestAndAccountItem]):
  /// 1. Guest-only items: adopted into the account store as-is.
  /// 2. Account-only items: left completely untouched.
  /// 3. Overlapping items: guest evidence deltas applied once (receipted);
  ///    earliest `introducedAt`/`firstRecallAt`, latest review stamps, and
  ///    deterministic SM-2 mastery re-evaluation.
  /// 4. Post-migration: `guestStore` is cleared and `accountStore` is durably
  ///    persisted exactly once, guaranteeing zero leakage to future guest
  ///    sessions or subsequent account logins.
  static Future<ReviewStateMigrationResult> migrateGuestToAccount({
    required ReviewStore guestStore,
    required ReviewStore accountStore,
    SharedPreferences? prefs,
    String? destinationOwnerKey,
    DateTime? now,
  }) async {
    if (prefs != null && destinationOwnerKey != null) {
      return ReviewMigrationEngine.migrateGuestToAccount(
        guestStore: guestStore,
        accountStore: accountStore,
        prefs: prefs,
        destinationOwnerKey: destinationOwnerKey,
        now: now,
      );
    }
    final guestItems = guestStore.all();
    if (guestItems.isEmpty) {
      return const ReviewStateMigrationResult(
        guestItemsCount: 0,
        adoptedCount: 0,
        mergedCount: 0,
      );
    }

    var adopted = 0;
    var merged = 0;

    for (final guestItem in guestItems) {
      if (guestItem.itemId.isEmpty) continue;

      final accountItem = accountStore.get(guestItem.itemId);
      if (accountItem == null) {
        accountStore.adoptRemote(guestItem);
        adopted++;
      } else {
        final reconciled = ReviewMigrationEngine.mergeGuestAndAccountItem(
          guestItem,
          accountItem,
        );
        accountStore.adoptRemote(reconciled);
        merged++;
      }
    }

    // Durably persist the target account store (exactly one write).
    await accountStore.persist();

    // Cleanly wipe the guest store to prevent leakage into other accounts.
    await guestStore.clear();

    return ReviewStateMigrationResult(
      guestItemsCount: guestItems.length,
      adoptedCount: adopted,
      mergedCount: merged,
    );
  }
}
