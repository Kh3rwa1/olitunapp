import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/home/presentation/home_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/home_screen_test.dart'
    show
        MockBannersNotifier,
        MockCategoryNotifier,
        MockLessonNotifier,
        MockLettersNotifier,
        MockMistakeNotifier,
        MockNumbersNotifier,
        MockQuizzesNotifier,
        MockSentencesNotifier,
        MockUserStatsNotifier,
        MockWordsNotifier;
import '../helpers/device_matrix.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() async {
    Animate.restartOnHotReload = false;
    Hive.init(
      (await Directory.systemTemp.createTemp('test_hive_home_matrix_')).path,
    );
    CacheService.resetForTesting();
  });

  for (final device in deviceMatrix) {
    testWidgets('Home lays out on $device', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      device.apply(tester);
      await tester.pumpWidget(
        createTestableWidget(
          child: const HomeScreen(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userNameProvider.overrideWith((ref) => 'Test User'),
            isAuthenticatedProvider.overrideWith((ref) async => true),
            userStarsProvider.overrideWith((ref) => 100),
            lessonsCompletedProvider.overrideWith((ref) => 2),
            categoryNotifierProvider.overrideWith(MockCategoryNotifier.new),
            lessonNotifierProvider.overrideWith(MockLessonNotifier.new),
            contentListProvider((
              ContentKind.lesson,
              null,
            )).overrideWith((ref) async => []),
            quizzesProvider.overrideWith(MockQuizzesNotifier.new),
            userStatsProvider.overrideWith(MockUserStatsNotifier.new),
            lastOpenedLessonIdProvider.overrideWith((ref) => null),
            bannersProvider.overrideWith(MockBannersNotifier.new),
            wordsProvider.overrideWith(MockWordsNotifier.new),
            numbersProvider.overrideWith(MockNumbersNotifier.new),
            sentencesProvider.overrideWith(MockSentencesNotifier.new),
            lettersProvider.overrideWith(MockLettersNotifier.new),
            appConnectivityProvider.overrideWith(
              (ref) => Stream.value([ConnectivityResult.wifi]),
            ),
            mistakeProvider.overrideWith(MockMistakeNotifier.new),
          ],
        ),
      );
      await pumpFrames(tester, frames: 30);
      expect(tester.takeException(), isNull);

      final greeting = find.text('Johar, Test User!');
      await tester.ensureVisible(greeting);
      await tester.pump();
      expect(greeting.hitTestable(), findsOneWidget);
      await pumpFrames(tester, frames: 25);
    });
  }
}
