import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../core/logging/app_logger.dart';

class MistakeItem {
  final String quizId;
  final int questionIndex;
  final QuizQuestion question;
  final String addedAt;

  MistakeItem({
    required this.quizId,
    required this.questionIndex,
    required this.question,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'questionIndex': questionIndex,
      'question': question.toMap(),
      'addedAt': addedAt,
    };
  }

  factory MistakeItem.fromJson(Map<String, dynamic> json) {
    return MistakeItem(
      quizId: json['quizId'] ?? '',
      questionIndex: json['questionIndex'] ?? 0,
      question: QuizQuestion.fromMap(
        Map<String, dynamic>.from(json['question'] ?? {}),
      ),
      addedAt: json['addedAt'] ?? '',
    );
  }
}

class MistakeNotifier extends StateNotifier<List<MistakeItem>> {
  final Ref _ref;
  static const String _prefKey = 'user_mistakes_list';
  static const String _masteredKey = 'user_mistakes_mastered_count';

  MistakeNotifier(this._ref) : super([]) {
    _loadMistakes();
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
  }) async {
    // Avoid duplicate records of same quiz/question
    final exists = state.any(
      (item) => item.quizId == quizId && item.questionIndex == questionIndex,
    );
    if (exists) return;

    final newItem = MistakeItem(
      quizId: quizId,
      questionIndex: questionIndex,
      question: question,
      addedAt: DateTime.now().toIso8601String(),
    );

    state = [...state, newItem];
    await _saveMistakes();
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
    }
  }

  Future<void> clearAll() async {
    state = [];
    await _saveMistakes();
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
