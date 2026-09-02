import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
// Exercised through the presentation compatibility barrel on purpose: the
// barrel must keep re-exporting account, stats and quiz result symbols.
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _stubStats = UserStatsEntity(
  practicedLetters: {'ᱚ'},
  completedLessons: {},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 12,
  lastActiveDate: '2026-09-01',
  currentStreak: 4,
  totalStars: 15,
);

/// Skips the cloud-backed bootstrapping so the barrel test stays offline.
class _StubUserStatsNotifier extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(_stubStats);
}

Future<ProviderContainer> containerFor(Map<String, Object> initialPrefs) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      userStatsProvider.overrideWith(_StubUserStatsNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('profile_providers compatibility barrel', () {
    test(
      're-exports account identity providers backed by preferences',
      () async {
        final container = await containerFor({});

        expect(container.read(userNameProvider), 'Learner');
        expect(container.read(userAvatarEmojiProvider), '👶');
        expect(container.read(userAvatarColorIndexProvider), 0);
        expect(container.read(memberSinceProvider), 'April 2024');
      },
    );

    test('re-exports account providers honouring stored preferences', () async {
      final container = await containerFor({
        'user_name': 'Somi',
        'user_avatar_emoji': '🦊',
        'user_avatar_color': 2,
      });

      expect(container.read(userNameProvider), 'Somi');
      expect(container.read(userAvatarEmojiProvider), '🦊');
      expect(container.read(userAvatarColorIndexProvider), 2);
    });

    test(
      're-exports the avatar palette provider with a non-empty palette',
      () async {
        final container = await containerFor({'user_avatar_color': 99});

        expect(container.read(userAvatarColorsProvider), isNotEmpty);
      },
    );

    test('re-exports the sync status provider in its idle default', () async {
      final container = await containerFor({});

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test(
      're-exports derived stat providers fed by the stats notifier',
      () async {
        final container = await containerFor({});

        expect(container.read(userStarsProvider), 15);
        expect(container.read(lessonsCompletedProvider), 0);
        expect(container.read(quizzesCompletedProvider), 0);
      },
    );

    test('re-exports QuizResultEntity for quiz history consumers', () {
      const result = QuizResultEntity(
        quizId: 'quiz-1',
        score: 8,
        totalQuestions: 10,
        completedAt: '2026-09-01T10:00:00Z',
      );

      expect(result.quizId, 'quiz-1');
      expect(result.score, 8);
      expect(result.totalQuestions, 10);
    });
  });
}
