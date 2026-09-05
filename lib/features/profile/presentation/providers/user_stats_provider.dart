// User stats: sync status, repository wiring, streak/star state and
// the [UserStatsNotifier] that owns stats mutations. Split out of
// profile_providers.dart by feature area.
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/domain/streak_week_logic.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/state_widgets.dart';

import 'profile_account_providers.dart';
part 'user_stats_notifier_helpers.dart';

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

/// Injectable clock for streak/date calculations.
final userStatsClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final userStatsProvider =
    NotifierProvider<UserStatsNotifier, AsyncValue<UserStatsEntity>>(
      UserStatsNotifier.new,
    );

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

class UserStatsNotifier extends Notifier<AsyncValue<UserStatsEntity>> {
  bool _disposed = false;

  DateTime Function() get _now => ref.read(userStatsClockProvider);

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  AsyncValue<UserStatsEntity> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadStats);
    Future.microtask(_syncProfileFromCloud);
    _setupConnectivityListener();
    return const AsyncValue.loading();
  }

  void _setupConnectivityListener() {
    Future.microtask(() {
      if (_disposed) return;
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
          if (_disposed) return;
          try {
            if (ref.read(syncStatusProvider) == SyncStatus.success) {
              ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
            }
          } catch (_) {
            // Container disposed during delay
          }
        });
      },
    );
  }

  Future<void> loadStats() async {
    if (_disposed) return;
    state = const AsyncValue.loading();
    final result = await _repository.getUserStats();
    if (_disposed) return;
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
    final updated = current.recordStarReward(
      starsAwarded,
      eventId: 'practice_${contentId}_${DateTime.now().microsecondsSinceEpoch}',
    );

    // 2. Track Analytics
    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
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
          ),
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

    unawaited(
      ref
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

    await updateStats(updated);
  }

  Future<void> practiceLetter(String letter, {double? score}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final normalizedLetter = letter.trim();
    if (normalizedLetter.isEmpty) return;

    final updatedLetters = Set<String>.from(current.practicedLetters)
      ..add(normalizedLetter);
    var updated = current.copyWith(practicedLetters: updatedLetters);

    const olChikiDigits = ['᱐', '᱑', '᱒', '᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙'];
    final isDigit = olChikiDigits.contains(normalizedLetter);

    if (isDigit) {
      final practicedDigits = updatedLetters
          .where(olChikiDigits.contains)
          .length;
      final masteryPct = (practicedDigits / 10 * 100).clamp(0, 100).round();
      final updatedMastery = Map<String, int>.from(updated.categoryMastery)
        ..['numbers'] = masteryPct;
      updated = _withStreakUpdate(
        updated.copyWith(categoryMastery: updatedMastery),
      );
    } else {
      final practicedAlphabetLetters = updatedLetters
          .where((l) => !olChikiDigits.contains(l))
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
        ref
            .read(learningAnalyticsServiceProvider)
            .track(
              LearningAnalyticsEvents.letterPracticed,
              source: 'practice_trace',
              sourceId: normalizedLetter,
              metadata: {
                'score': double.parse(score.toStringAsFixed(2)),
                'isDigit': isDigit,
              },
            ),
      );
    }

    await updateStats(updated);
  }

  Future<void> addStars(int count) async {
    try {
      final current = state.valueOrNull;
      if (current == null) return;
      if (count <= 0) return;

      final updated = _withStreakUpdate(current.recordStarReward(count));
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

    var updated = current.copyWith(completedLessons: updatedLessons);
    if (!alreadyCompleted) {
      updated = updated.recordLearningMinutes(
        estimatedMinutes.clamp(0, 240),
        eventId: 'lesson_$lessonId',
      );
    }

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
        ref
            .read(learningAnalyticsServiceProvider)
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
            ),
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
        ref
            .read(learningAnalyticsServiceProvider)
            .track(
              LearningAnalyticsEvents.quizCompleted,
              source: 'quiz',
              sourceId: sanitized.quizId,
              learnerLevel: updated.learnerLevel,
              metadata: {
                'score': sanitized.score,
                'totalQuestions': sanitized.totalQuestions,
                'percent': (sanitized.score / sanitized.totalQuestions * 100)
                    .round(),
                'passed': sanitized.isPassing,
              },
            ),
      );
    } catch (e, st) {
      AppLogger.debug('Failed to save quiz result: $e\n$st');
    }
  }

  Future<void> resetProgress() async {
    final result = await _repository.resetUserStats();
    if (_disposed) return;
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (stats) {
        state = AsyncValue.data(stats);
        _updateSyncStateFromPrefs();
      },
    );
  }

  Future<void> updateName(String name) async {
    ref.read(userNameProvider.notifier).state = name;
    final result = await _repository.updateDisplayName(name);
    result.fold(
      (failure) =>
          AppLogger.debug('Profile: Failed to save display name: $failure'),
      (_) {},
    );
  }

  Future<void> updateAvatar(String emoji, int colorIndex) async {
    final result = await _repository.updateAvatar(emoji, colorIndex);
    result.fold((failure) => null, (_) {
      ref.read(userAvatarEmojiProvider.notifier).state = emoji;
      ref.read(userAvatarColorIndexProvider.notifier).state = colorIndex;
    });
  }
}
