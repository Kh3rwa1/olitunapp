import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class MistakeItem {
  final String quizId;
  final String questionId;
  final int questionIndex;
  final QuizQuestion question;
  final String addedAt;

  MistakeItem({
    required this.quizId,
    String? questionId,
    required this.questionIndex,
    required this.question,
    required this.addedAt,
  }) : questionId = questionId ?? '${quizId}_$questionIndex';

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'questionId': questionId,
      'questionIndex': questionIndex,
      'question': question.toMap(),
      'addedAt': addedAt,
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

class MistakeNotifier extends StateNotifier<List<MistakeItem>> {
  final Ref _ref;
  static const String _prefKey = 'user_mistakes_list';
  static const String _masteredKey = 'user_mistakes_mastered_count';

  MistakeNotifier(this._ref) : super([]) {
    _loadMistakes();
    unawaited(syncFromBackend());
  }

  void _loadMistakes() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        state = decoded
            .map(
              (item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to load mistakes: $e');
      state = [];
    }
  }

  Future<void> _saveMistakes() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final raw = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_prefKey, raw);
    } catch (e) {
      AppLogger.debug('MistakeNotifier: Failed to save mistakes: $e');
    }
  }

  int get masteredCount {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getInt(_masteredKey) ?? 0;
  }

  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {
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
    final originalLength = state.length;
    state = state
        .where(
          (item) =>
              !(item.quizId == quizId && item.questionIndex == questionIndex),
        )
        .toList();

    if (state.length < originalLength) {
      await _saveMistakes();

      // Increment mastered count
      final prefs = _ref.read(sharedPreferencesProvider);
      final count = prefs.getInt(_masteredKey) ?? 0;
      await prefs.setInt(_masteredKey, count + 1);
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
      final functions = Functions(
        _ref.read(appwriteAuthServiceProvider).client,
      );
      final response = await functions.createExecution(
        functionId: 'completeMistakeReview',
        body: jsonEncode({
          'questionIds': reviewedMistakes
              .map((item) => '${item.quizId}:${item.questionId}')
              .toList(),
          'masteredQuestionIds': masteredMistakes
              .map((item) => '${item.quizId}:${item.questionId}')
              .toList(),
          'score': score,
          'total': total,
        }),
      );
      if (response.status.name != 'completed') {
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
    final isAuth = _ref.read(isAuthenticatedProvider).value ?? false;
    if (!isAuth) return;

    try {
      final functions = Functions(
        _ref.read(appwriteAuthServiceProvider).client,
      );
      final response = await functions.createExecution(
        functionId: 'getUserMistakes',
        body: jsonEncode({}),
      );
      if (response.status.name != 'completed') return;
      final data = jsonDecode(response.responseBody);
      if (data is! Map || data['ok'] != true || data['mistakes'] is! List) {
        return;
      }
      final remote = (data['mistakes'] as List)
          .map((item) => MistakeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final merged = <String, MistakeItem>{
        for (final item in state) '${item.quizId}:${item.questionId}': item,
        for (final item in remote) '${item.quizId}:${item.questionId}': item,
      };
      state = merged.values.toList(growable: false);
      await _saveMistakes();
    } catch (e) {
      AppLogger.debug('MistakeNotifier: backend sync skipped: $e');
    }
  }

  Future<void> _recordMistakeRemotely({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {
    try {
      final functions = Functions(
        _ref.read(appwriteAuthServiceProvider).client,
      );
      final correctAnswer = _correctAnswerFor(question);
      await functions.createExecution(
        functionId: 'recordMistake',
        body: jsonEncode({
          'quizId': quizId,
          'questionId': '${quizId}_$questionIndex',
          'questionIndex': questionIndex,
          'wrongAnswer': wrongAnswer ?? '',
          'correctAnswer': correctAnswer,
          'questionSnapshot': question.toMap(),
        }),
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
      final functions = Functions(
        _ref.read(appwriteAuthServiceProvider).client,
      );
      await functions.createExecution(
        functionId: 'markMistakeMastered',
        body: jsonEncode({
          'quizId': quizId,
          'questionId': '${quizId}_$questionIndex',
          'questionIndex': questionIndex,
        }),
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

final mistakeProvider =
    StateNotifierProvider<MistakeNotifier, List<MistakeItem>>((ref) {
      return MistakeNotifier(ref);
    });

final mistakesMasteredCountProvider = Provider<int>((ref) {
  // Watch mistakeProvider so we rebuild if mistakes change
  ref.watch(mistakeProvider);
  return ref.read(mistakeProvider.notifier).masteredCount;
});
