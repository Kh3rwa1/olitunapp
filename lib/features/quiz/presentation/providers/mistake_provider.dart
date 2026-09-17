import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/appwrite_functions_service.dart';
import '../../../../core/auth/account_scope.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../review/data/review_store.dart';
import '../../../review/data/review_store_notifier.dart';
import '../../../review/domain/review_item.dart';
import '../../domain/quiz_memory_resolver.dart';
import 'mistake_item.dart';
import 'mistake_storage.dart';

export 'mistake_item.dart';

/// Domain terms live in mistake_item.dart; account-scoped persistence and
/// legacy/guest migration live in mistake_storage.dart. This file owns the
/// derived recovery queue, the durable backend outbox, and provider wiring.

class MistakeNotifier extends Notifier<List<MistakeItem>> {
  // Legacy mastered counter is read-only compat (SRS derives mastery).
  static const String _legacyMasteredKey = 'user_mistakes_mastered_count';

  StreamSubscription<SharedPreferences>? _scopeSubscription;

  @override
  List<MistakeItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    // Account switch: dispose this owner's state and reload for the new
    // owner. Stale cross-account state is never published.
    _scopeSubscription?.cancel();
    final captured = mistakeOwnerSuffix(prefs);
    _scopeSubscription = AccountScope.changes.listen((changedPrefs) {
      if (mistakeOwnerSuffix(changedPrefs) != captured) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(() {
      _scopeSubscription?.cancel();
      _scopeSubscription = null;
    });
    // Listen to canonical ReviewStore updates to ensure convergence.
    // Only SRS-mastered items auto-resolve (Review state NEVER resolves).
    ref.listen<AsyncValue<ReviewStore>>(reviewStoreProvider, (previous, next) {
      final store = next.valueOrNull;
      if (store != null) {
        unawaited(reconcileWithReviewStore(store));
      }
    });
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadMistakes);
    unawaited(Future.microtask(syncFromBackend));
    unawaited(Future.microtask(_replayOutbox));
    return [];
  }

  /// Recovery criterion (explicit policy): the attributed item recorded
  /// strictly more successful recalls AFTER the mistake than at record
  /// time. One correct recall after the mistake recovers the queue item —
  /// without ever calling Review state "mastered" and without touching any
  /// mastered counter. Non-memory questions (unresolvable to SRS) never
  /// auto-recover; they resolve only via explicit [resolveMistake].
  bool _hasRecovered(ReviewStore? store, MistakeItem item) {
    if (store == null) return false;
    final resolved = resolveQuizMemoryItem(item.question);
    if (resolved == null) return false;
    final memItem = store.get(resolved.itemId);
    if (memItem == null) return false;
    return memItem.successfulRecalls > item.baselineSuccesses;
  }

  List<MistakeItem> _loadResolvedAudit() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(mistakeAuditKey(mistakeOwnerSuffix(prefs)));
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded
            .map(
              (item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to load resolved audit: $e');
    }
    return [];
  }

  Future<void> _saveResolvedAudit(List<MistakeItem> audit) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final bounded = audit.length > 500
          ? audit.sublist(audit.length - 500)
          : audit;
      final raw = jsonEncode(bounded.map((item) => item.toJson()).toList());
      await prefs.setString(mistakeAuditKey(mistakeOwnerSuffix(prefs)), raw);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to save resolved audit: $e');
    }
  }

  List<MistakeItem> get resolvedAudit => _loadResolvedAudit();

  void _loadMistakes() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final suffix = mistakeOwnerSuffix(prefs);
      unawaited(claimLegacyMistakes(prefs, suffix));
      final store = ref.read(reviewStoreProvider).valueOrNull;
      final resolvedAudit = _loadResolvedAudit();
      final resolvedKeys = {
        for (final item in resolvedAudit) '${item.quizId}:${item.questionId}',
      };

      state = readMistakeList(prefs, mistakeListKey(suffix)).where((item) {
        final key = '${item.quizId}:${item.questionId}';
        if (item.isResolved || resolvedKeys.contains(key)) {
          return false;
        }
        // Recovered items (criterion met after record time) leave the queue.
        if (_hasRecovered(store, item)) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to load mistakes: $e');
      state = [];
    }
  }

  Future<void> _saveMistakes() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(mistakeListKey(mistakeOwnerSuffix(prefs)), raw);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to save mistakes: $e');
    }
  }

  /// Mastered count is DERIVED from the SRS authority only. Review state
  /// never increments it, and local resolution never fabricates it. The
  /// legacy counter key is read-only compat for pre-scoped installs.
  int get masteredCount {
    final store = ref.read(reviewStoreProvider).valueOrNull;
    if (store != null) {
      return store.countsByState()[MasteryState.mastered] ?? 0;
    }
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      return prefs.getInt(_legacyMasteredKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // --- Durable account-scoped outbox for backend mistake mutations ---

  List<MistakeOutboxEntry> _readOutbox(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(mistakeOutboxKey(mistakeOwnerSuffix(prefs)));
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => MistakeOutboxEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeOutbox(
    SharedPreferences prefs,
    List<MistakeOutboxEntry> entries,
  ) async {
    await prefs.setString(
      mistakeOutboxKey(mistakeOwnerSuffix(prefs)),
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Number of unacknowledged backend mistake mutations (diagnostics).
  int get pendingBackendMutations {
    try {
      return _readOutbox(ref.read(sharedPreferencesProvider)).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _enqueueOutbox(MistakeOutboxEntry entry) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final entries = _readOutbox(prefs);
      if (entries.any((e) => e.idempotencyKey == entry.idempotencyKey)) return;
      entries.add(entry);
      await _writeOutbox(prefs, entries);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: outbox enqueue failed: $e');
    }
  }

  Future<void> _replayOutbox() async {
    late final SharedPreferences prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } catch (_) {
      return;
    }
    final entries = _readOutbox(prefs);
    if (entries.isEmpty) return;
    final remaining = <MistakeOutboxEntry>[];
    for (final entry in entries) {
      final ok = await _sendOutboxEntry(entry);
      if (!ok) remaining.add(entry);
    }
    await _writeOutbox(prefs, remaining);
  }

  /// Sends one entry. Returns true when acknowledged (or safely droppable).
  /// Failures stay queued — never logged-and-swallowed.
  Future<bool> _sendOutboxEntry(MistakeOutboxEntry entry) async {
    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      final String functionId;
      switch (entry.kind) {
        case 'record':
          functionId = 'recordMistake';
          break;
        case 'resolve':
          // Deployed compat function id. It resolves the recovery TASK
          // (audit), not SRS mastery — see deprecation note on
          // [masterMistake] and functions/markMistakeMastered/README.
          functionId = 'markMistakeMastered';
          break;
        case 'complete':
          functionId = 'completeMistakeReview';
          break;
        default:
          return true; // Unknown kind: drop (forward-compat).
      }
      final response = await functions.execute(functionId, body: entry.body);
      return response.isCompleted;
    } catch (e) {
      AppLogger.debug(
        'MistakeNotifier: backend ${entry.kind} queued for retry: $e',
      );
      return false;
    }
  }

  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {
    final qId = '${quizId}_$questionIndex';
    final audit = _loadResolvedAudit();
    final hadAudit = audit.any(
      (a) => a.quizId == quizId && a.questionId == qId,
    );
    if (hadAudit) {
      audit.removeWhere((a) => a.quizId == quizId && a.questionId == qId);
      await _saveResolvedAudit(audit);
    }

    // Avoid duplicate records of same quiz/question
    final exists = state.any(
      (item) => item.quizId == quizId && item.questionIndex == questionIndex,
    );
    if (!exists) {
      // Capture the SRS baseline for the recovery criterion. Non-memory
      // questions resolve to null and keep baseline 0 (history only, never
      // auto-recovered via SRS).
      var baseline = 0;
      try {
        final store = ref.read(reviewStoreProvider).valueOrNull;
        final resolved = resolveQuizMemoryItem(question);
        if (resolved != null) {
          baseline = store?.get(resolved.itemId)?.successfulRecalls ?? 0;
        }
      } catch (_) {
        baseline = 0;
      }
      final newItem = MistakeItem(
        quizId: quizId,
        questionIndex: questionIndex,
        question: question,
        addedAt: DateTime.now().toIso8601String(),
        baselineSuccesses: baseline,
      );

      state = [...state, newItem];
      await _saveMistakes();
    }

    // Durable backend record with a retry-stable idempotency key. The SRS
    // recall/failure operation for attributable answers is recorded by the
    // quiz/review flows via ReviewStore (single authority); non-memory
    // questions keep quiz history here and never enter SRS.
    await _enqueueOutbox(
      MistakeOutboxEntry(
        idempotencyKey: 'mistake:$qId',
        kind: 'record',
        body: {
          'quizId': quizId,
          'questionId': qId,
          'questionIndex': questionIndex,
          'wrongAnswer': wrongAnswer ?? '',
          'correctAnswer': _correctAnswerFor(question),
          'questionSnapshot': question.toMap(),
        },
        enqueuedAt: DateTime.now().toIso8601String(),
      ),
    );
    unawaited(_replayOutbox());
  }

  /// Resolves a recovery TASK (removes it from the queue, appends audit).
  /// This does NOT award SRS mastery — only [MasteryState.mastered] does.
  /// Remote acknowledgement is durable: failures stay in the outbox.
  Future<void> resolveMistake({
    required String quizId,
    required int questionIndex,
  }) async {
    final toResolve = state
        .where(
          (item) =>
              item.quizId == quizId && item.questionIndex == questionIndex,
        )
        .toList();

    if (toResolve.isNotEmpty) {
      final audit = _loadResolvedAudit();
      final nowStr = DateTime.now().toIso8601String();
      for (final item in toResolve) {
        final resolvedItem = item.copyWith(
          isResolved: true,
          resolvedAt: nowStr,
        );
        audit.removeWhere(
          (a) => a.quizId == item.quizId && a.questionId == item.questionId,
        );
        audit.add(resolvedItem);
      }
      await _saveResolvedAudit(audit);

      state = state
          .where(
            (item) =>
                !(item.quizId == quizId && item.questionIndex == questionIndex),
          )
          .toList();
      await _saveMistakes();

      await _enqueueOutbox(
        MistakeOutboxEntry(
          idempotencyKey: 'resolve:$quizId:${toResolve.first.questionId}',
          kind: 'resolve',
          body: {
            'quizId': quizId,
            'questionId': toResolve.first.questionId,
            'questionIndex': questionIndex,
          },
          enqueuedAt: nowStr,
        ),
      );
      unawaited(_replayOutbox());
    }
  }

  /// Deprecated misleading name. Use [resolveMistake]: completing a review
  /// task is not SRS mastery. Removal planned once call sites migrate.
  @Deprecated('Use resolveMistake instead. Removal: v1.5.0.')
  Future<void> masterMistake({
    required String quizId,
    required int questionIndex,
  }) => resolveMistake(quizId: quizId, questionIndex: questionIndex);

  Future<void> completeReviewSession({
    required int score,
    required int total,
    required List<MistakeItem> reviewedMistakes,
    required List<MistakeItem> masteredMistakes,
  }) async {
    await _enqueueOutbox(
      MistakeOutboxEntry(
        idempotencyKey:
            'complete:${DateTime.now().millisecondsSinceEpoch}:$score:$total',
        kind: 'complete',
        body: {
          'questionIds': reviewedMistakes
              .map((item) => '${item.quizId}:${item.questionId}')
              .toList(),
          'masteredQuestionIds': masteredMistakes
              .map((item) => '${item.quizId}:${item.questionId}')
              .toList(),
          'score': score,
          'total': total,
        },
        enqueuedAt: DateTime.now().toIso8601String(),
      ),
    );
    unawaited(_replayOutbox());
  }

  Future<void> clearAll() async {
    state = [];
    await _saveMistakes();
  }

  /// Guest -> account mistake migration (union semantics in
  /// mistake_storage.dart). Called on sign-in.
  Future<void> migrateGuestMistakes() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final merged = await mergeGuestMistakes(prefs, mistakeOwnerSuffix(prefs));
      if (merged) _loadMistakes();
    } catch (e) {
      AppLogger.debug('MistakeNotifier: guest migration failed: $e');
    }
  }

  Future<void> syncFromBackend() async {
    final isAuth = ref.read(isAuthenticatedProvider).value ?? false;
    if (!isAuth) return;

    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      final response = await functions.execute('getUserMistakes');
      if (!response.isCompleted) return;
      final data = response.bodyJson;
      if (data == null || data['ok'] != true || data['mistakes'] is! List) {
        return;
      }
      final remote = (data['mistakes'] as List)
          .map((item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // UNIFIED CANONICAL LEARNING MEMORY STATE:
      // Reinstall/backend sync must never resurrect mistakes for items already
      // resolved locally or SRS-mastered in the canonical ReviewStore.
      // Review (non-mastered) items stay queued: Review is not recovery.
      final store = ref.read(reviewStoreProvider).valueOrNull;
      final resolvedAudit = _loadResolvedAudit();
      final resolvedKeys = {
        for (final item in resolvedAudit) '${item.quizId}:${item.questionId}',
      };

      final filteredRemote = remote.where((item) {
        final key = '${item.quizId}:${item.questionId}';
        if (item.isResolved || resolvedKeys.contains(key)) {
          return false;
        }
        if (_hasRecovered(store, item)) {
          return false;
        }
        return true;
      });

      final merged = <String, MistakeItem>{
        for (final item in state) '${item.quizId}:${item.questionId}': item,
        for (final item in filteredRemote)
          '${item.quizId}:${item.questionId}': item,
      };
      state = merged.values.toList(growable: false);
      await _saveMistakes();
    } catch (e) {
      AppLogger.debug('MistakeNotifier: backend sync skipped: $e');
    }
  }

  /// Reconciles mistake state when an item is recalled in Today's Review or
  /// other retrieval sessions. Resolution follows the explicit recovery
  /// criterion (new successes after record time), never bare lifecycle
  /// state: Review-without-new-success stays queued.
  Future<void> reconcileRecoveredItem(String itemId) async {
    final store = ref.read(reviewStoreProvider).valueOrNull;
    final toResolve = state.where((item) {
      final resolved = resolveQuizMemoryItem(item.question);
      if (resolved != null) {
        if (resolved.itemId != itemId) return false;
        return _hasRecovered(store, item);
      }
      if (item.question.sourceWordId == itemId ||
          item.question.sourceSentenceId == itemId ||
          item.questionId == itemId ||
          item.quizId == itemId) {
        return _hasRecovered(store, item);
      }
      return false;
    }).toList();

    for (final m in toResolve) {
      await resolveMistake(quizId: m.quizId, questionIndex: m.questionIndex);
    }
  }

  /// Reconciles all active mistakes against a snapshot of canonical
  /// ReviewStore states. Items meeting the recovery criterion resolve;
  /// anything else (including Review-but-not-recovered) remains queued.
  Future<void> reconcileWithReviewStore(ReviewStore store) async {
    final toResolve = state.where((item) {
      return _hasRecovered(store, item);
    }).toList();

    for (final m in toResolve) {
      await resolveMistake(quizId: m.quizId, questionIndex: m.questionIndex);
    }
  }

  String _correctAnswerFor(QuizQuestion question) {
    if ((question.correctAnswer ?? '').isNotEmpty) {
      return question.correctAnswer!;
    }
    final index = question.correctIndex;
    if (index >= 0 && index < question.optionsLatin.length) {
      return question.optionsLatin[index];
    }
    if (index >= 0 && index < question.optionsOlChiki.length) {
      return question.optionsOlChiki[index];
    }
    return '';
  }
}

final mistakeProvider = NotifierProvider<MistakeNotifier, List<MistakeItem>>(
  MistakeNotifier.new,
);

final mistakesMasteredCountProvider = Provider<int>((ref) {
  // Watch mistakeProvider so we rebuild if mistakes change
  ref.watch(mistakeProvider);
  return ref.read(mistakeProvider.notifier).masteredCount;
});
