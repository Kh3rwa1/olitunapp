// Review state cloud sync: startup + connectivity + post-mutation replay.
//
// Mirrors the existing ContentMutationReplay init pattern (startup pass +
// connectivity-regained replay) so the two offline-first systems behave
// identically. Deliberately NO periodic Timer: under mobile Doze periodic
// Dart timers don't fire reliably, and the outbox drains opportunistically
// after every local mutation instead (near-zero push latency when online).
// Entries whose backoff window hasn't elapsed are skipped by the replay
// loop, so offline retries cost one cheap local scan, not network hammering.
// Watched at the app root (main.dart) to keep the loop alive.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/appwrite_db_service.dart';
import '../../../core/api/appwrite_functions_service.dart';
import '../../../core/auth/appwrite_auth_service.dart';
import '../../../core/offline/mutation_outbox_service.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/hive_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/review_corpus_identity.dart';
import 'review_appwrite_repository.dart';
import 'review_state_migration.dart';
import 'review_state_sync.dart';
import 'review_store.dart';

final reviewStateSyncProvider = Provider<ReviewStateSync>((ref) {
  final store = ref.watch(reviewStoreProvider.notifier);
  final corpusMap = ref.watch(corpusIdentityMapProvider).valueOrNull;
  final sync = ReviewStateSync(
    repository: ReviewAppwriteRepository(
      ref.watch(appwriteDbServiceProvider),
      ref.watch(appwriteFunctionsServiceProvider),
    ),
    outbox: MutationOutboxAdapter(ref.watch(mutationOutboxProvider)),
    resolveUserId: () async {
      try {
        // Cheap signed-out fast path: never hit the network when the
        // account state already says signed out (also keeps widget/smoke
        // tests from opening real HttpClients, whose idle timers outlive
        // the test). Awaited (not valueOrNull): the override/future may
        // still be loading on a cold start. Unknown on timeout still
        // falls through to getMe() below.
        final signedIn = await ref
            .read(isAuthenticatedProvider.future)
            .timeout(const Duration(seconds: 3));
        if (!signedIn) return null;
        final user = await ref
            .watch(appwriteAuthServiceProvider)
            .getMe()
            .timeout(const Duration(seconds: 3));
        return user.$id;
      } catch (_) {
        return null;
      }
    },
    loadStore: store.current,
    corpusMap: corpusMap,
    onStoreUpdated: store.notifyStoreChanged,
  );
  // Attaches the durable cloud-write hook to the notifier (field-only,
  // no state change). From here on, every local mutation enqueues a
  // cloud write in the same call.
  store.attachSync(sync);
  return sync;
});

/// App-lifetime sync loop. Returns void; the sync service owns the work.
final reviewSyncInitProvider = Provider<void>((ref) {
  final sync = ref.watch(reviewStateSyncProvider);

  void runSync() {
    // Fire-and-forget: failures are logged and retried on the next tick.
    // ignore: discarded_futures
    sync.syncNow();
  }

  // Startup: pull + merge + drain queued writes.
  Future.microtask(runSync);

  // Auth state change (e.g. login/restore): migrate guest progress and sync immediately.
  ref.listen<AsyncValue<bool>>(isAuthenticatedProvider, (previous, next) async {
    if (next.value == true && previous?.value != true) {
      sync.clearCachedUserId();
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        const guestKey = 'review_states_guest';
        if (prefs.containsKey(guestKey)) {
          final guestStore = await ReviewStore.load(prefs, storageKey: guestKey);
          final accountStore = await ref.read(reviewStoreProvider.notifier).current();
          final migration = await ReviewStateMigrator.migrateGuestToAccount(
            guestStore: guestStore,
            accountStore: accountStore,
          );
          if (migration.hasChanges) {
            ref.read(reviewStoreProvider.notifier).notifyStoreChanged();
          }
        }
      } catch (e) {
        AppLogger.debug('ReviewSyncInit: guest migration note: $e');
      }
      runSync();
    }
  });

  // Connectivity regained: sync immediately.
  ref.listen<AsyncValue<List<ConnectivityResult>>>(appConnectivityProvider, (
    previous,
    next,
  ) {
    final prevOffline =
        previous?.value?.contains(ConnectivityResult.none) ?? true;
    final nextOnline =
        next.value != null && !next.value!.contains(ConnectivityResult.none);
    if (prevOffline && nextOnline) runSync();
  });
});
