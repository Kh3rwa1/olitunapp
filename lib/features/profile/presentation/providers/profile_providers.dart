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
  return ProfileRepositoryImpl(authRepo);
});

final userStatsProvider = StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStatsEntity>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return UserStatsNotifier(repo);
});

final userNameProvider = StateProvider<String>((ref) {
  // We'll keep using prefs directly for now to avoid breaking too much, 
  // but eventually this should come from the repository.
  return prefs.getString('user_name') ?? 'Learner';
});

final userAvatarEmojiProvider = StateProvider<String>((ref) {
  return prefs.getString('user_avatar_emoji') ?? '👶';
});

final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return prefs.getInt('user_avatar_color') ?? 0;
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
  return prefs.getString('member_since') ?? 'April 2024';
});

final userAvatarColorsProvider = Provider<List<Color>>((ref) {
  final index = ref.watch(userAvatarColorIndexProvider);
  return AppColors.avatarPalettes[index.clamp(0, AppColors.avatarPalettes.length - 1)];
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
    result.fold(
      (failure) => null, // Handle error
      (_) => state = AsyncValue.data(stats),
    );
  }

  Future<void> practiceLetter(String letter) async {
    final current = state.value;
    if (current == null) return;
    
    final updatedLetters = Set<String>.from(current.practicedLetters)..add(letter);
    final updated = current.copyWith(practicedLetters: updatedLetters);
    await updateStats(updated);
  }

  Future<void> addStars(int count) async {
    final current = state.value;
    if (current == null) return;
    
    final updated = current.copyWith(totalStars: current.totalStars + count);
    await updateStats(updated);
  }

  Future<void> completeLesson(String lessonId) async {
    final current = state.value;
    if (current == null) return;
    
    final updatedLessons = Set<String>.from(current.completedLessons)..add(lessonId);
    final updated = current.copyWith(completedLessons: updatedLessons);
    await updateStats(updated);
  }

  Future<void> saveQuizResult(QuizResultEntity result) async {
    final current = state.value;
    if (current == null) return;
    
    final updatedHistory = Map<String, QuizResultEntity>.from(current.quizHistory)
      ..[result.quizId] = result;
    final updated = current.copyWith(quizHistory: updatedHistory);
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
    result.fold(
      (failure) => null,
      (_) {
        ref.read(userAvatarEmojiProvider.notifier).state = emoji;
        ref.read(userAvatarColorIndexProvider.notifier).state = colorIndex;
      },
    );
  }
}
