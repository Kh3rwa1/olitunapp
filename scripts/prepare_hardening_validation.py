import os
from pathlib import Path

def patch(path, old, new):
    p = Path(path)
    s = p.read_text()
    assert s.count(old) == 1, f'Expected one anchor in {path}: {old[:80]}'
    p.write_text(s.replace(old, new, 1))

area = os.environ['AREA']
assert area in {'web', 'progress'}
if area == 'web':
    path = 'lib/features/home/presentation/widgets/home_content_grid.dart'
    patch(path, 'if (secondaryTitle != null) secondaryTitle,', '?secondaryTitle,')
    path = 'test/features/home/widgets/home_category_accessibility_test.dart'
    patch(path, 'show SemanticsAction, SemanticsFlag;', 'show SemanticsAction;')
    patch(path, 'data.hasFlag(SemanticsFlag.isButton)', 'data.flagsCollection.isButton')
    patch(path, '\n    addTearDown(handle.dispose);\n', '\n    try {\n')
    patch(path, '\n      addTearDown(handle.dispose);\n', '\n      try {\n')
    patch(path, '    expect(tester.takeException(), isNull);\n  });', '    expect(tester.takeException(), isNull);\n    } finally {\n      handle.dispose();\n    }\n  });')
    patch(path, "      );\n    });\n  }\n\n  for (final key", "      );\n      } finally {\n        handle.dispose();\n      }\n    });\n  }\n\n  for (final key")

if area == 'progress':
    path = 'test/features/profile/user_stats_notifier_test.dart'
    old = '''    test('resetProgress clears all stats', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));

      final container = _containerFor(mockRepo);
      addTearDown(container.dispose);
      final notifier = container.read(userStatsProvider.notifier);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.resetProgress();
      final stats = notifier.state.value!;
      expect(stats.quizHistory.isEmpty, isTrue);
    });'''
    new = '''    test('resetProgress uses the explicit reset contract', () async {
      const reset = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
        syncEpoch: 1,
      );
      when(mockRepo.getUserStats).thenAnswer((_) async => const Right(baseStats));
      when(mockRepo.resetUserStats).thenAnswer((_) async => const Right(reset));
      final container = _containerFor(mockRepo);
      addTearDown(container.dispose);
      final notifier = container.read(userStatsProvider.notifier);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.resetProgress();
      final stats = notifier.state.value!;
      expect(stats, reset);
      expect(stats.practicedLetters, isEmpty);
      expect(stats.completedLessons, isEmpty);
      expect(stats.totalStars, 0);
      expect(stats.syncEpoch, 1);
      verify(mockRepo.resetUserStats).called(1);
      verifyNever(() => mockRepo.updateUserStats(any()));
    });

    test('resetProgress reports a failed reset', () async {
      when(mockRepo.getUserStats).thenAnswer((_) async => const Right(baseStats));
      when(mockRepo.resetUserStats).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'reset failed')),
      );
      final container = _containerFor(mockRepo);
      addTearDown(container.dispose);
      final notifier = container.read(userStatsProvider.notifier);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await notifier.resetProgress();
      expect(notifier.state.hasError, isTrue);
      verifyNever(() => mockRepo.updateUserStats(any()));
    });'''
    patch(path, old, new)

print(f'Applied diagnostic-driven {area} corrections.')
