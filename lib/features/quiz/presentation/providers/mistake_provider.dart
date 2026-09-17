import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/appwrite_functions_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../review/data/review_store.dart';
import '../../../review/domain/review_item.dart';
import '../../domain/quiz_memory_resolver.dart';

class MistakeItem {
  final String quizId;
  final String questionId;
  final int questionIndex;
  final QuizQuestion question;
  final String addedAt;
  final bool isResolved;
  final String? resolvedAt;

  MistakeItem({
    required this.quizId,
    String? questionId,
    required this.questionIndex,
    required this.question,
    required this.addedAt,
    this.isResolved = false,
    this.resolvedAt,
  }) : questionId = questionId ?? '${quizId}_$questionIndex';

  MistakeItem copyWith({
    String? quizId,
    String? questionId,
    int? questionIndex,
    QuizQuestion? question,
    String? addedAt,
    bool? isResolved,
    String? resolvedAt,
  }) {
    return MistakeItem(
      quizId: quizId ?? this.quizId,
      questionId: questionId ?? this.questionId,
      questionIndex: questionIndex ?? this.questionIndex,
      question: question ?? this.question,
      addedAt: addedAt ?? this.addedAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'questionId': questionId,
      'questionIndex': questionIndex,
      'question': question.toMap(),
      'addedAt': addedAt,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt,
    };
  }

  factory MistakeItem.fromJson(Map<String, dynamic> json) {
    final snapshot = json['question'] ?? json['questionSnapshot'];
    return MistakeItem(
      quizId: json['quizId'] ?? '',
      questionId: json['questionId'] as String?,
      questionIndex: json['questionIndex'] ?? 0,
      question: QuizQuestion.fromMap(_readQuestionSnapshot(snapshot)),
      addedAt: json['addedAt'] ?? json['lastMissedAt'] ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] as String?,
    );
  }

  static Map<String, dynamic> _readQuestionSnapshot(dynamic snapshot) {
    try {
      if (snapshot is String && snapshot.trim().isNotEmpty) {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      if (snapshot is Map) {
        return Map<String, dynamic>.from(snapshot);
      }
    } catch (_) {
      // Remote mistakes should never break the local review queue.
    }
    return <String, dynamic>{};
  }
}

class MistakeNotifier extends Notifier<List<MistakeItem>> {
  static const String _prefKey = 'user_mistakes_list';
  static const String _masteredKey = 'user_mistakes_mastered_count';
  static const String _resolvedAuditKey = 'user_mistakes_resolved_audit_v1';

  @override
  List<MistakeItem> build() {
    ref.onDispose(() {
      // Provider disposed — pending backend sync result will be dropped by Riverpod.
    });
    // Listen to canonical ReviewStore updates to ensure convergence
    ref.listen<AsyncValue<ReviewStore>>(reviewStoreProvider, (previous, next) {
      final store = next.valueOrNull;
      if (store != null) {
        unawaited(reconcileWithReviewStore(store));
      }
    });
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadMistakes);
    unawaited(Future.microtask(syncFromBackend));
    return [];
  }

  bool _isItemMasteredOrInReview(ReviewStore? store, QuizQuestion question) {
    if (store == null) return false;
    final resolved = resolveQuizMemoryItem(question);
    if (resolved != null) {
      final memItem = store.get(resolved.itemId);
      if (memItem != null) {
        return memItem.masteryState == MasteryState.mastered ||
            memItem.masteryState == MasteryState.review;
      }
    }
    return false;
  }

  List<MistakeItem> _loadResolvedAudit() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(_resolvedAuditKey);
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
      final bounded =
          audit.length > 500 ? audit.sublist(audit.length - 500) : audit;
      final raw = jsonEncode(bounded.map((item) => item.toJson()).toList());
      await prefs.setString(_resolvedAuditKey, raw);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to save resolved audit: $e');
    }
  }

  List<MistakeItem> get resolvedAudit => _loadResolvedAudit();

  void _loadMistakes() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final store = ref.read(reviewStoreProvider).valueOrNull;
        final resolvedAudit = _loadResolvedAudit();
        final resolvedKeys = {
          for (final item in resolvedAudit) '${item.quizId}:${item.questionId}',
        };

        state = decoded
            .map(
              (item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) {
              final key = '${item.quizId}:${item.questionId}';
              if (item.isResolved || resolvedKeys.contains(key)) {
                return false;
              }
              if (_isItemMasteredOrInReview(store, item.question)) {
                return false;
              }
              return true;
            })
            .toList();
      }
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to load mistakes: $e');
      state = [];
    }
  }

  Future<void> _saveMistakes() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_prefKey, raw);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to save mistakes: $e');
    }
  }

  int get masteredCount {
    final store = ref.read(reviewStoreProvider).valueOrNull;
    if (store != null) {
      return store.countsByState()[MasteryState.mastered] ?? 0;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getInt(_masteredKey) ?? 0;
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
      final newItem = MistakeItem(
        quizId: quizId,
        questionIndex: questionIndex,
        question: question,
        addedAt: DateTime.now().toIso8601String(),
      );

      state = [...state, newItem];
      await _saveMistakes();
    }

    await _recordMistakeRemotely(
      quizId: quizId,
      questionIndex: questionIndex,
      question: question,
      wrongAnswer: wrongAnswer,
    );
  }

  Future<void> masterMistake({
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

      // Increment mastered count
      final prefs = ref.read(sharedPreferencesProvider);
      final count = prefs.getInt(_masteredKey) ?? 0;
      await prefs.setInt(_masteredKey, count + toResolve.length);

      await _markMistakeMasteredRemotely(
        quizId: quizId,
        questionIndex: questionIndex,
      );
    }
  }

  Future<void> completeReviewSession({
    required int score,
    required int total,
    required List<MistakeItem> reviewedMistakes,
    required List<MistakeItem> masteredMistakes,
  }) async {
    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      final response = await functions.execute(
        'completeMistakeReview',
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
      );
      if (!response.isCompleted) {
        throw Exception('completeMistakeReview did not complete');
      }
    } catch (e) {
      AppLogger.debug('MistakeNotifier: complete review sync failed: $e');
    }
  }

  Future<void> clearAll() async {
    state = [];
    await _saveMistakes();
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
      // resolved locally or mastered/in-review in the canonical ReviewStore.
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
        if (_isItemMasteredOrInReview(store, item.question)) {
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

  /// Reconciles legacy mistake state when an item is successfully recalled
  /// or mastered in Today's Review or other retrieval sessions.
  Future<void> reconcileRecoveredItem(String itemId) async {
    final toMaster = state.where((item) {
      final resolved = resolveQuizMemoryItem(item.question);
      if (resolved != null && resolved.itemId == itemId) return true;
      if (item.question.sourceWordId == itemId ||
          item.question.sourceSentenceId == itemId ||
          item.questionId == itemId ||
          item.quizId == itemId) {
        return true;
      }
      return false;
    }).toList();

    for (final m in toMaster) {
      await masterMistake(quizId: m.quizId, questionIndex: m.questionIndex);
    }
  }

  /// Reconciles all active mistakes against a snapshot of canonical ReviewStore states.
  Future<void> reconcileWithReviewStore(ReviewStore store) async {
    final toMaster = state.where((item) {
      return _isItemMasteredOrInReview(store, item.question);
    }).toList();

    for (final m in toMaster) {
      await masterMistake(quizId: m.quizId, questionIndex: m.questionIndex);
    }
  }

  Future<void> _recordMistakeRemotely({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {
    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      final correctAnswer = _correctAnswerFor(question);
      await functions.execute(
        'recordMistake',
        body: {
          'quizId': quizId,
          'questionId': '${quizId}_$questionIndex',
          'questionIndex': questionIndex,
          'wrongAnswer': wrongAnswer ?? '',
          'correctAnswer': correctAnswer,
          'questionSnapshot': question.toMap(),
        },
      );
    } catch (e) {
      AppLogger.debug('MistakeNotifier: remote record failed: $e');
    }
  }

  Future<void> _markMistakeMasteredRemotely({
    required String quizId,
    required int questionIndex,
  }) async {
    try {
      final functions = ref.read(appwriteFunctionsServiceProvider);
      await functions.execute(
        'markMistakeMastered',
        body: {
          'quizId': quizId,
          'questionId': '${quizId}_$questionIndex',
          'questionIndex': questionIndex,
        },
      );
    } catch (e) {
      AppLogger.debug('MistakeNotifier: remote mastery failed: $e');
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
