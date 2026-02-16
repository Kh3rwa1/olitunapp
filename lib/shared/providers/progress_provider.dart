import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../features/auth/data/auth_repository.dart';

/// Comprehensive user progress tracking
class UserProgressData {
  static const List<String> _levelThresholds = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Master',
  ];
  final Set<String> practicedLetters;
  final Set<String> completedLessons;
  final Map<String, QuizResult> quizHistory;
  final Map<String, int>
  categoryMastery; // 0=Beginner, 1=Intermediate, 2=Advanced
  final int totalLearningMinutes;
  final String lastActiveDate; // ISO date string YYYY-MM-DD
  final int currentStreak;
  final int totalStars;
  final DateTime? sessionStartTime;

  UserProgressData({
    Set<String>? practicedLetters,
    Set<String>? completedLessons,
    Map<String, QuizResult>? quizHistory,
    Map<String, int>? categoryMastery,
    this.totalLearningMinutes = 0,
    this.lastActiveDate = '',
    this.currentStreak = 0,
    this.totalStars = 0,
    this.sessionStartTime,
  }) : practicedLetters = practicedLetters ?? {},
       completedLessons = completedLessons ?? {},
       quizHistory = quizHistory ?? {},
       categoryMastery = categoryMastery ?? {};

  factory UserProgressData.fromJson(Map<String, dynamic> json) {
    return UserProgressData(
      practicedLetters: Set<String>.from(json['practicedLetters'] ?? []),
      completedLessons: Set<String>.from(json['completedLessons'] ?? []),
      quizHistory:
          (json['quizHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, QuizResult.fromJson(v)),
          ) ??
          {},
      categoryMastery: Map<String, int>.from(json['categoryMastery'] ?? {}),
      totalLearningMinutes: json['totalLearningMinutes'] ?? 0,
      lastActiveDate: json['lastActiveDate'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      totalStars: json['totalStars'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'practicedLetters': practicedLetters.toList(),
    'completedLessons': completedLessons.toList(),
    'quizHistory': quizHistory.map((k, v) => MapEntry(k, v.toJson())),
    'categoryMastery': categoryMastery,
    'totalLearningMinutes': totalLearningMinutes,
    'lastActiveDate': lastActiveDate,
    'currentStreak': currentStreak,
    'totalStars': totalStars,
  };

  UserProgressData copyWith({
    Set<String>? practicedLetters,
    Set<String>? completedLessons,
    Map<String, QuizResult>? quizHistory,
    Map<String, int>? categoryMastery,
    int? totalLearningMinutes,
    String? lastActiveDate,
    int? currentStreak,
    int? totalStars,
    DateTime? sessionStartTime,
  }) {
    return UserProgressData(
      practicedLetters: practicedLetters ?? this.practicedLetters,
      completedLessons: completedLessons ?? this.completedLessons,
      quizHistory: quizHistory ?? this.quizHistory,
      categoryMastery: categoryMastery ?? this.categoryMastery,
      totalLearningMinutes: totalLearningMinutes ?? this.totalLearningMinutes,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      totalStars: totalStars ?? this.totalStars,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  // ============== COMPUTED PROPERTIES ==============

  double get alphabetProgress {
    const totalLetters = 30;
    return (practicedLetters.length / totalLetters).clamp(0.0, 1.0);
  }

  double get numbersProgress {
    final numberLessons = completedLessons
        .where((id) => id.startsWith('numbers_'))
        .length;
    const totalNumbers = 10;
    return (numberLessons / totalNumbers).clamp(0.0, 1.0);
  }

  double get vocabularyProgress {
    final wordLessons = completedLessons
        .where((id) => id.startsWith('words_'))
        .length;
    const totalWords = 20;
    return (wordLessons / totalWords).clamp(0.0, 1.0);
  }

  double get rhymesProgress {
    final rhymeLessons = completedLessons
        .where((id) => id.startsWith('rhymes_'))
        .length;
    const totalRhymes = 10;
    return (rhymeLessons / totalRhymes).clamp(0.0, 1.0);
  }

  int get lessonsCompletedCount => completedLessons.length;
  int get quizzesCompletedCount => quizHistory.length;

  double get quizAccuracy {
    if (quizHistory.isEmpty) return 0.0;
    int totalCorrect = 0;
    int totalQuestions = 0;
    for (final result in quizHistory.values) {
      totalCorrect += result.score;
      totalQuestions += result.totalQuestions;
    }
    if (totalQuestions == 0) return 0.0;
    return totalCorrect / totalQuestions;
  }

  int get todayCompletions {
    final today = _todayString();
    int count = 0;
    for (final result in quizHistory.values) {
      if (result.completedAt.startsWith(today)) count++;
    }
    return count;
  }

  /// Overall progress across all skill areas (0.0 - 1.0)
  double get overallProgress {
    final skills = [
      alphabetProgress,
      numbersProgress,
      vocabularyProgress,
      rhymesProgress,
    ];
    if (skills.isEmpty) return 0.0;
    return skills.reduce((a, b) => a + b) / skills.length;
  }

  /// Learner level based on overall progress and stars
  String get learnerLevel {
    final progress = overallProgress;
    final lessons = lessonsCompletedCount;
    if (progress >= 0.75 && lessons >= 20) return _levelThresholds[3];
    if (progress >= 0.5 && lessons >= 10) return _levelThresholds[2];
    if (progress >= 0.2 && lessons >= 3) return _levelThresholds[1];
    return _levelThresholds[0];
  }

  /// Level index (0-3) for gradient coloring
  int get levelIndex {
    return _levelThresholds.indexOf(learnerLevel).clamp(0, 3);
  }

  /// Best individual quiz score percentage
  int get bestQuizScore {
    if (quizHistory.isEmpty) return 0;
    double best = 0;
    for (final result in quizHistory.values) {
      if (result.totalQuestions > 0) {
        final pct = result.score / result.totalQuestions;
        if (pct > best) best = pct;
      }
    }
    return (best * 100).round();
  }
}

class QuizResult {
  final String quizId;
  final int score;
  final int totalQuestions;
  final String completedAt; // ISO timestamp

  QuizResult({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completedAt: json['completedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'quizId': quizId,
    'score': score,
    'totalQuestions': totalQuestions,
    'completedAt': completedAt,
  };

  bool get isPassing => totalQuestions > 0 && (score / totalQuestions) >= 0.7;
}

// ============== NOTIFIER ==============

class ProgressNotifier extends StateNotifier<UserProgressData> {
  final AuthRepository? _authRepository;

  ProgressNotifier({AuthRepository? authRepository})
    : _authRepository = authRepository,
      super(UserProgressData()) {
    _load();
    _startSession();
  }

  static const _key = 'user_progress_data';

  void _load() {
    final stored = prefs.getString(_key);
    if (stored != null) {
      try {
        final data = UserProgressData.fromJson(jsonDecode(stored));
        state = data.copyWith(sessionStartTime: DateTime.now());
        _checkStreak();
      } catch (e) {
        state = UserProgressData(sessionStartTime: DateTime.now());
      }
    } else {
      state = UserProgressData(sessionStartTime: DateTime.now());
    }
  }

  void _save() {
    prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void _startSession() {
    state = state.copyWith(sessionStartTime: DateTime.now());
  }

  void _checkStreak() {
    final today = _todayString();
    final yesterday = _yesterdayString();

    if (state.lastActiveDate != today && state.lastActiveDate != yesterday) {
      state = state.copyWith(currentStreak: 0);
      _save();
    }
  }

  void practiceLetter(String letterChar) {
    final updated = Set<String>.from(state.practicedLetters)..add(letterChar);
    state = state.copyWith(practicedLetters: updated);
    _save();
  }

  void completeLesson(String lessonId) {
    final updated = Set<String>.from(state.completedLessons)..add(lessonId);
    final today = _todayString();
    int newStreak = state.currentStreak;
    if (state.lastActiveDate != today) {
      final yesterday = _yesterdayString();
      newStreak = state.lastActiveDate == yesterday
          ? state.currentStreak + 1
          : 1;
    }
    state = state.copyWith(
      completedLessons: updated,
      currentStreak: newStreak,
      lastActiveDate: today,
    );
    _save();
  }

  void addStars(int amount) {
    state = state.copyWith(totalStars: state.totalStars + amount);
    _save();
  }

  void completeQuiz(
    String quizId,
    int score,
    int totalQuestions, {
    String? categoryId,
  }) {
    final result = QuizResult(
      quizId: quizId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: DateTime.now().toIso8601String(),
    );

    final updatedHistory = Map<String, QuizResult>.from(state.quizHistory);
    updatedHistory[quizId] = result;

    final today = _todayString();
    int newStreak = state.currentStreak;

    if (result.isPassing && state.lastActiveDate != today) {
      newStreak = state.currentStreak + 1;
    }

    final updatedMastery = Map<String, int>.from(state.categoryMastery);
    if (categoryId != null && result.isPassing) {
      final currentLevel = updatedMastery[categoryId] ?? 0;
      final percentage = score / totalQuestions;
      if (percentage >= 0.9 && currentLevel < 2) {
        updatedMastery[categoryId] = currentLevel + 1;
      }
    }

    state = state.copyWith(
      quizHistory: updatedHistory,
      categoryMastery: updatedMastery,
      currentStreak: newStreak,
      lastActiveDate: today,
    );
    _save();
    syncWithCloud();
  }

  Future<void> syncWithCloud() async {
    if (_authRepository == null) return;
    try {
      await _authRepository.updateMetadata(state.toJson());
      print('Progress synced to cloud');
    } catch (e) {
      print('Cloud sync failed: $e');
    }
  }

  void addLearningTime(int minutes) {
    state = state.copyWith(
      totalLearningMinutes: state.totalLearningMinutes + minutes,
    );
    _save();
  }

  void flushSessionTime() {
    if (state.sessionStartTime == null) return;
    final elapsed = DateTime.now()
        .difference(state.sessionStartTime!)
        .inMinutes;
    if (elapsed > 0) {
      addLearningTime(elapsed);
      state = state.copyWith(sessionStartTime: DateTime.now());
    }
  }
}

// ============== HELPERS ==============

String _todayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _yesterdayString() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
}
