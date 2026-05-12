import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
export 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepositoryImpl(authRepo, prefs);
});

final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStatsEntity>>((
      ref,
    ) {
      final repo = ref.watch(profileRepositoryProvider);
      return UserStatsNotifier(repo);
    });

final userNameProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('user_name') ??
      'Learner';
});

final userAvatarEmojiProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('user_avatar_emoji') ??
      '👶';
});

final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return ref.read(sharedPreferencesProvider).getInt('user_avatar_color') ?? 0;
});

final userStarsProvider = Provider<int>((ref) {
  final stats = ref.watch(userStatsProvider).value;
  return stats?.totalStars ?? 0;
});

final lessonsCompletedProvider = Provider<int>((ref) {
  final stats = ref.watch(userStatsProvider).value;
  return stats?.lessonsCompletedCount ?? 0;
});

final quizzesCompletedProvider = Provider<int>((ref) {
  final stats = ref.watch(userStatsProvider).value;
  return stats?.quizzesCompletedCount ?? 0;
});

final memberSinceProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('member_since') ??
      'April 2024';
});

final userAvatarColorsProvider = Provider<List<Color>>((ref) {
  final index = ref.watch(userAvatarColorIndexProvider);
  return AppColors.avatarPalettes[index.clamp(
    0,
    AppColors.avatarPalettes.length - 1,
  )];
});

class UserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>> {
  final ProfileRepository _repository;

  UserStatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    final result = await _repository.getUserStats();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (stats) => state = AsyncValue.data(stats),
    );
  }

  Future<void> updateStats(UserStatsEntity stats) async {
    final result = await _repository.updateUserStats(stats);
    result.fold((failure) => null, (_) => state = AsyncValue.data(stats));
  }

  /// Updates lastActiveDate and currentStreak based on today's date.
  UserStatsEntity _withStreakUpdate(UserStatsEntity stats) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = stats.lastActiveDate;

    if (lastDate == today) return stats.copyWith(lastActiveDate: today);

    // Check if last active was yesterday
    int newStreak = 1;
    if (lastDate.isNotEmpty) {
      try {
        final lastDay = DateTime.parse(lastDate);
        final diff = DateTime.now().difference(lastDay).inDays;
        if (diff == 1) {
          newStreak = stats.currentStreak + 1;
        }
      } catch (_) {
        // Malformed date, reset streak
      }
    }

    return stats.copyWith(lastActiveDate: today, currentStreak: newStreak);
  }

  /// Resolves a category key from a categoryId for mastery tracking.
  String _normalizeCategoryKey(String categoryId) {
    final lower = categoryId.toLowerCase();
    if (lower.contains('alphabet') || lower.contains('letter')) {
      return 'alphabets';
    }
    if (lower.contains('number')) return 'numbers';
    if (lower.contains('word') || lower.contains('vocab')) return 'words';
    if (lower.contains('sentence') || lower.contains('phrase')) {
      return 'sentences';
    }
    if (lower.contains('rhyme')) return 'rhymes';
    return categoryId;
  }

  Future<void> practiceLetter(String letter) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedLetters = Set<String>.from(current.practicedLetters)
      ..add(letter);
    var updated = current.copyWith(practicedLetters: updatedLetters);

    // Update alphabet mastery based on practiced letters
    final masteryPct = (updatedLetters.length / 30 * 100).clamp(0, 100).round();
    final updatedMastery = Map<String, int>.from(updated.categoryMastery)
      ..['alphabets'] = masteryPct;
    updated = _withStreakUpdate(
      updated.copyWith(categoryMastery: updatedMastery),
    );

    await updateStats(updated);
  }

  Future<void> addStars(int count) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(totalStars: current.totalStars + count);
    await updateStats(updated);
  }

  /// Marks a lesson as completed and updates:
  /// - completedLessons set
  /// - categoryMastery percentage
  /// - totalLearningMinutes
  /// - streak / lastActiveDate
  Future<void> completeLesson(
    String lessonId, {
    String? categoryId,
    int estimatedMinutes = 5,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedLessons = Set<String>.from(current.completedLessons)
      ..add(lessonId);

    var updated = current.copyWith(
      completedLessons: updatedLessons,
      totalLearningMinutes: current.totalLearningMinutes + estimatedMinutes,
    );

    // Update category mastery if we know the category
    if (categoryId != null && categoryId.isNotEmpty) {
      final key = _normalizeCategoryKey(categoryId);
      final currentMastery = Map<String, int>.from(updated.categoryMastery);
      final oldVal = currentMastery[key] ?? 0;
      // Each completed lesson in this category adds ~10% mastery, capped at 100
      currentMastery[key] = (oldVal + 10).clamp(0, 100);
      updated = updated.copyWith(categoryMastery: currentMastery);
    }

    updated = _withStreakUpdate(updated);
    await updateStats(updated);
  }

  Future<void> saveQuizResult(QuizResultEntity result) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedHistory = Map<String, QuizResultEntity>.from(
      current.quizHistory,
    )..[result.quizId] = result;

    final updated = _withStreakUpdate(
      current.copyWith(quizHistory: updatedHistory),
    );
    await updateStats(updated);
  }

  Future<void> resetProgress() async {
    const empty = UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    );
    await updateStats(empty);
  }

  Future<void> updateName(WidgetRef ref, String name) async {
    final result = await _repository.updateDisplayName(name);
    result.fold(
      (failure) => null,
      (_) => ref.read(userNameProvider.notifier).state = name,
    );
  }

  Future<void> updateAvatar(WidgetRef ref, String emoji, int colorIndex) async {
    final result = await _repository.updateAvatar(emoji, colorIndex);
    result.fold((failure) => null, (_) {
      ref.read(userAvatarEmojiProvider.notifier).state = emoji;
      ref.read(userAvatarColorIndexProvider.notifier).state = colorIndex;
    });
  }
}
