import 'package:itun/core/logging/app_logger.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
export 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/analytics/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../shared/widgets/state_widgets.dart';

enum SyncStatus { idle, syncing, success, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final isStatsSyncedProvider = StateProvider<bool>((ref) {
  final val =
      ref.watch(sharedPreferencesProvider).getBool('is_stats_synced') ?? true;
  return val;
});

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
      return UserStatsNotifier(repo, ref: ref);
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

final badgeTraditionalArcherNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_archer_name') ??
      'Santali Archer';
});

final badgeTraditionalKudumNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_kudum_name') ??
      'Kudum Master';
});

final badgeTraditionalKherwalNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_kherwal_name') ??
      'Kherwal Elder';
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
  final Ref? _ref;
  final DateTime Function() _now;

  UserStatsNotifier(this._repository, {Ref? ref, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _ref = ref,
      super(const AsyncValue.loading()) {
    loadStats();
    _syncProfileFromCloud();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    final ref = _ref;
    if (ref == null) return;
    Future.microtask(() {
      if (!mounted) return;
      ref.listen<AsyncValue<List<ConnectivityResult>>>(
        appConnectivityProvider,
        (previous, next) {
          next.whenOrNull(
            data: (results) {
              final isOffline =
                  results.contains(ConnectivityResult.none) || results.isEmpty;
              final previouslyOffline =
                  previous == null ||
                  previous.valueOrNull == null ||
                  previous.valueOrNull!.contains(ConnectivityResult.none) ||
                  previous.valueOrNull!.isEmpty;
              if (!isOffline && previouslyOffline) {
                syncPendingStats();
              }
            },
          );
        },
      );
    });
  }

  Future<void> syncPendingStats() async {
    final ref = _ref;
    if (ref == null) return;

    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    final result = await _repository.syncPendingStats();
    await result.fold(
      (failure) async {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
        ref.read(isStatsSyncedProvider.notifier).state = false;
      },
      (_) async {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
        ref.read(isStatsSyncedProvider.notifier).state = true;
        // Silent reload of stats to get the merged cloud progress without flashing loading state
        final statsResult = await _repository.getUserStats();
        statsResult.fold((failure) => null, (mergedStats) {
          state = AsyncValue.data(mergedStats);
          _updateSyncStateFromPrefs();
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (ref.read(syncStatusProvider) == SyncStatus.success) {
            ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
          }
        });
      },
    );
  }

  void _updateSyncStateFromPrefs() {
    final ref = _ref;
    if (ref == null) return;
    final isSynced =
        ref.read(sharedPreferencesProvider).getBool('is_stats_synced') ?? true;
    ref.read(isStatsSyncedProvider.notifier).state = isSynced;
  }

  Future<void> loadStats() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    final result = await _repository.getUserStats();
    if (!mounted) return;
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (stats) {
        state = AsyncValue.data(stats);
        _updateSyncStateFromPrefs();
      },
    );
  }

  /// Fetches current user from Appwrite and updates local name if it's still 'Learner'
  Future<void> _syncProfileFromCloud() async {
    final ref = _ref;
    if (ref == null) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userResult = await authRepo.getCurrentUser();

      userResult.fold(
        (failure) =>
            AppLogger.debug('ProfileSync: Failed to get user: $failure'),
        (user) {
          if (user != null && user.name != null && user.name!.isNotEmpty) {
            final currentName = ref.read(userNameProvider);
            final firstName = user.name!.split(' ').first;
            if (currentName == 'Learner' ||
                currentName == 'Explorer' ||
                currentName != firstName) {
              AppLogger.debug(
                'ProfileSync: Syncing first name from cloud: $firstName',
              );
              updateName(firstName);
            }
          }
        },
      );
    } catch (e) {
      AppLogger.debug('ProfileSync: Error during sync: $e');
    }
  }

  Future<void> updateStats(UserStatsEntity stats) async {
    final previous = state.valueOrNull;
    final result = await _repository.updateUserStats(stats);
    result.fold((failure) => null, (mergedStats) {
      state = AsyncValue.data(mergedStats);
      _updateSyncStateFromPrefs();
      _trackStreakMaintained(previous, mergedStats);
      _trackStreakMilestone(previous, mergedStats);
    });
  }

  void _trackStreakMilestone(
    UserStatsEntity? previous,
    UserStatsEntity current,
  ) {
    final ref = _ref;
    if (ref == null || previous == null) return;
    if (current.currentStreak <= previous.currentStreak) return;

    const milestones = [3, 7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (previous.currentStreak < milestone &&
          current.currentStreak >= milestone) {
        unawaited(
          ref
              .read(learningAnalyticsServiceProvider)
              .track(
                LearningAnalyticsEvents.streakMilestone,
                source: 'profile_stats',
                sourceId: 'streak_$milestone',
                metadata: {
                  'milestone': milestone,
                  'currentStreak': current.currentStreak,
                },
              ),
        );
      }
    }
  }

  void _trackStreakMaintained(
    UserStatsEntity? previous,
    UserStatsEntity current,
  ) {
    final ref = _ref;
    if (ref == null || previous == null) return;
    if (current.currentStreak <= 0) return;
    if (current.lastActiveDate.isEmpty ||
        current.lastActiveDate == previous.lastActiveDate) {
      return;
    }

    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.streakMaintained,
            source: 'profile_stats',
            sourceId: current.lastActiveDate,
            learnerLevel: current.learnerLevel,
            metadata: {
              'currentStreak': current.currentStreak,
              'previousStreak': previous.currentStreak,
            },
          ),
    );
  }

  /// Updates lastActiveDate and currentStreak based on today's date.
  UserStatsEntity _withStreakUpdate(UserStatsEntity stats) {
    final now = _now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = todayDate.toIso8601String().substring(0, 10);
    final lastDate = stats.lastActiveDate;

    if (lastDate == today) return stats.copyWith(lastActiveDate: today);

    int newStreak = 1;
    if (lastDate.isNotEmpty) {
      final parsedLastDay = DateTime.tryParse(lastDate);
      if (parsedLastDay != null) {
        final lastDay = DateTime(
          parsedLastDay.year,
          parsedLastDay.month,
          parsedLastDay.day,
        );
        final diff = todayDate.difference(lastDay).inDays;
        if (diff == 1) {
          newStreak = stats.currentStreak + 1;
        } else if (diff == 0) {
          newStreak = stats.currentStreak;
        } else {
          newStreak = 1;
        }
      }
    }

    return stats.copyWith(lastActiveDate: today, currentStreak: newStreak);
  }

  Future<void> recordPracticeCompletion({
    required String contentId,
    required String contentType,
    required String practiceMode,
    required int attempts,
    required bool withHint,
    required int starsAwarded,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // 1. Award Stars
    final updated = current.copyWith(
      totalStars: current.totalStars + starsAwarded,
    );

    // 2. Track Analytics
    unawaited(
      _ref
              ?.read(learningAnalyticsServiceProvider)
              .track(
                LearningAnalyticsEvents.practiceCompleted,
                source: 'typing_practice',
                sourceId: contentId,
                metadata: {
                  'contentType': contentType,
                  'practiceMode': practiceMode,
                  'attempts': attempts,
                  'withHint': withHint,
                  'starsAwarded': starsAwarded,
                },
              ) ??
          Future.value(),
    );

    // 3. Increment streak and save stats
    await updateStats(_withStreakUpdate(updated));
  }

  Future<void> recordDailyMissionsCompletedToday() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final now = _now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = todayDate.toIso8601String().substring(0, 10);

    if (current.completedMissionsDates.contains(today)) return;

    final updatedDates = Set<String>.from(current.completedMissionsDates)
      ..add(today);

    // Calculate weekId of today using ISO-like week number
    final year = todayDate.year;
    final firstDayOfYear = DateTime(year);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final daysSinceFirstMonday = todayDate.difference(firstMonday).inDays;
    final week = (daysSinceFirstMonday / 7).floor() + 1;
    final weekId = '$year-W$week';

    // Count how many days in this week have completed daily missions
    int completedDaysThisWeek = 0;
    for (final dateStr in updatedDates) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        final dYear = date.year;
        final dFirstDay = DateTime(dYear);
        final dOffset = dFirstDay.weekday - 1;
        final dFirstMonday = dFirstDay.subtract(Duration(days: dOffset));
        final dDaysSince = date.difference(dFirstMonday).inDays;
        final dWeek = (dDaysSince / 7).floor() + 1;
        final dWeekId = '$dYear-W$dWeek';
        if (dWeekId == weekId) {
          completedDaysThisWeek++;
        }
      }
    }

    final updated = current.copyWith(completedMissionsDates: updatedDates);

    if (_ref != null) {
      unawaited(
        _ref
            .read(learningAnalyticsServiceProvider)
            .track(
              LearningAnalyticsEvents.dailyMissionCompleted,
              source: 'daily_missions',
              sourceId: today,
              metadata: {
                'weekId': weekId,
                'completedDaysThisWeek': completedDaysThisWeek,
              },
            ),
      );
    }

    await updateStats(updated);
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

  Future<void> practiceLetter(String letter, {double? score}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final normalizedLetter = letter.trim();
    if (normalizedLetter.isEmpty) return;

    final updatedLetters = Set<String>.from(current.practicedLetters)
      ..add(normalizedLetter);
    var updated = current.copyWith(practicedLetters: updatedLetters);

    final isDigit = const [
      '᱐',
      '᱑',
      '᱒',
      '᱓',
      '᱔',
      '᱕',
      '᱖',
      '᱗',
      '᱘',
      '᱙',
    ].contains(normalizedLetter);

    if (isDigit) {
      final practicedDigits = updatedLetters
          .where(
            (l) => const [
              '᱐',
              '᱑',
              '２',
              '３',
              '᱔',
              '᱕',
              '᱖',
              '᱗',
              '᱘',
              '᱙',
            ].contains(l),
          )
          .length;
      final masteryPct = (practicedDigits / 10 * 100).clamp(0, 100).round();
      final updatedMastery = Map<String, int>.from(updated.categoryMastery)
        ..['numbers'] = masteryPct;
      updated = _withStreakUpdate(
        updated.copyWith(categoryMastery: updatedMastery),
      );
    } else {
      final practicedAlphabetLetters = updatedLetters
          .where(
            (l) => !const [
              '᱐',
              '᱑',
              '２',
              '３',
              '᱔',
              '᱕',
              '᱖',
              '᱗',
              '᱘',
              '᱙',
            ].contains(l),
          )
          .length;
      final masteryPct =
          (practicedAlphabetLetters / UserStatsEntity.alphabetLetterCount * 100)
              .clamp(0, 100)
              .round();
      final updatedMastery = Map<String, int>.from(updated.categoryMastery)
        ..['alphabets'] = masteryPct;
      updated = _withStreakUpdate(
        updated.copyWith(categoryMastery: updatedMastery),
      );
    }

    if (score != null) {
      unawaited(
        _ref
                ?.read(learningAnalyticsServiceProvider)
                .track(
                  LearningAnalyticsEvents.letterPracticed,
                  source: 'practice_trace',
                  sourceId: normalizedLetter,
                  metadata: {
                    'score': double.parse(score.toStringAsFixed(2)),
                    'isDigit': isDigit,
                  },
                ) ??
            Future.value(),
      );
    }

    await updateStats(updated);
  }

  Future<void> addStars(int count) async {
    try {
      final current = state.valueOrNull;
      if (current == null) return;
      if (count <= 0) return;

      final updated = _withStreakUpdate(
        current.copyWith(totalStars: current.totalStars + count),
      );
      await updateStats(updated);
    } catch (e, st) {
      AppLogger.debug('Failed to add stars: $e\n$st');
    }
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

    final alreadyCompleted = current.completedLessons.contains(lessonId);
    final updatedLessons = Set<String>.from(current.completedLessons)
      ..add(lessonId);

    var updated = current.copyWith(
      completedLessons: updatedLessons,
      totalLearningMinutes: alreadyCompleted
          ? current.totalLearningMinutes
          : current.totalLearningMinutes + estimatedMinutes.clamp(0, 240),
    );

    // Update category mastery only the first time a lesson is completed.
    if (!alreadyCompleted && categoryId != null && categoryId.isNotEmpty) {
      final key = _normalizeCategoryKey(categoryId);
      final currentMastery = Map<String, int>.from(updated.categoryMastery);
      final oldVal = currentMastery[key] ?? 0;
      // Each completed lesson in this category adds ~10% mastery, capped at 100
      currentMastery[key] = (oldVal + 10).clamp(0, 100);
      updated = updated.copyWith(categoryMastery: currentMastery);
    }

    updated = _withStreakUpdate(updated);
    await updateStats(updated);
    if (!alreadyCompleted) {
      unawaited(
        _ref
                ?.read(learningAnalyticsServiceProvider)
                .track(
                  LearningAnalyticsEvents.lessonCompleted,
                  source: 'lesson_detail',
                  sourceId: lessonId,
                  learnerLevel: updated.learnerLevel,
                  metadata: {
                    'categoryId': categoryId,
                    'estimatedMinutes': estimatedMinutes.clamp(0, 240),
                    'totalCompletedLessons': updated.completedLessons.length,
                  },
                ) ??
            Future.value(),
      );
    }
  }

  Future<void> saveQuizResult(QuizResultEntity result) async {
    try {
      final current = state.valueOrNull;
      if (current == null) return;
      if (result.quizId.trim().isEmpty || result.totalQuestions <= 0) return;

      final sanitized = QuizResultEntity(
        quizId: result.quizId.trim(),
        score: result.score.clamp(0, result.totalQuestions),
        totalQuestions: result.totalQuestions,
        completedAt: result.completedAt.isNotEmpty
            ? result.completedAt
            : _now().toIso8601String(),
        failedNoHearts: result.failedNoHearts,
      );

      final updatedHistory = Map<String, QuizResultEntity>.from(
        current.quizHistory,
      );
      final key = updatedHistory.containsKey(sanitized.quizId)
          ? '${sanitized.quizId}@${sanitized.completedAt}'
          : sanitized.quizId;
      updatedHistory[key] = sanitized;

      final updated = _withStreakUpdate(
        current.copyWith(quizHistory: updatedHistory),
      );
      await updateStats(updated);
      unawaited(
        _ref
                ?.read(learningAnalyticsServiceProvider)
                .track(
                  LearningAnalyticsEvents.quizCompleted,
                  source: 'quiz',
                  sourceId: sanitized.quizId,
                  learnerLevel: updated.learnerLevel,
                  metadata: {
                    'score': sanitized.score,
                    'totalQuestions': sanitized.totalQuestions,
                    'percent':
                        (sanitized.score / sanitized.totalQuestions * 100)
                            .round(),
                    'passed': sanitized.isPassing,
                  },
                ) ??
            Future.value(),
      );
    } catch (e, st) {
      AppLogger.debug('Failed to save quiz result: $e\n$st');
    }
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

  Future<void> updateName(String name) async {
    final ref = _ref;
    if (ref == null) return;

    ref.read(userNameProvider.notifier).state = name;
    final result = await _repository.updateDisplayName(name);
    result.fold(
      (failure) =>
          AppLogger.debug('Profile: Failed to save display name: $failure'),
      (_) {},
    );
  }

  Future<void> updateAvatar(String emoji, int colorIndex) async {
    final ref = _ref;
    if (ref == null) return;

    final result = await _repository.updateAvatar(emoji, colorIndex);
    result.fold((failure) => null, (_) {
      ref.read(userAvatarEmojiProvider.notifier).state = emoji;
      ref.read(userAvatarColorIndexProvider.notifier).state = colorIndex;
    });
  }
}
