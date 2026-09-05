import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/home/presentation/home_screen.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:hive/hive.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import '../../test_utils.dart';

class MockCategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([]);
}

class MockLessonNotifier extends LessonNotifier {
  @override
  AsyncValue<List<LessonEntity>> build() => const AsyncValue.data([]);
}

class MockQuizzesNotifier extends QuizzesNotifier {
  @override
  AsyncValue<List<QuizModel>> build() => const AsyncValue.data([]);
}

class MockBannersNotifier extends BannersNotifier {
  @override
  AsyncValue<List<FeaturedBannerModel>> build() => const AsyncValue.data([]);
}

class MockWordsNotifier extends WordsNotifier {
  @override
  AsyncValue<List<WordModel>> build() => const AsyncValue.data([]);
}

class MockNumbersNotifier extends NumbersNotifier {
  @override
  AsyncValue<List<NumberModel>> build() => const AsyncValue.data([]);
}

class MockSentencesNotifier extends SentencesNotifier {
  @override
  AsyncValue<List<SentenceModel>> build() => const AsyncValue.data([]);
}

class MockLettersNotifier extends LettersNotifier {
  @override
  AsyncValue<List<LetterModel>> build() => const AsyncValue.data([]);
}

class MockUserStatsNotifier extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 10,
      lastActiveDate: '',
      currentStreak: 2,
      totalStars: 100,
    ),
  );
}

class MockMistakeNotifier extends MistakeNotifier {
  @override
  List<MistakeItem> build() => [];
}

class MockAffirmationsNotifier extends AffirmationsNotifier {
  @override
  AsyncValue<List<AffirmationModel>> build() => AsyncValue.data([
    AffirmationModel(
      id: 'aff_1',
      olChikiText: 'ᱚᱞ ᱪᱤᱠᱤ',
      santaliPhonetic: 'ol chiki',
      englishMeaning: 'Ol Chiki is beautiful',
      category: 'identity',
      order: 1,
      publishedAt: '',
    ),
  ]);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable flutter_animate effects in tests to prevent pending timers
    Animate.restartOnHotReload = false;
    Hive.init('test_hive_home_v2');
    CacheService.resetForTesting();
  });

  tearDownAll(() async {
    // No-op to see if closing Hive/Cache was causing the event loop hang.
  });

  testWidgets('HomeScreen renders greeting and daily progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final categoryNotifier = MockCategoryNotifier();
    final lessonNotifier = MockLessonNotifier();
    final userStatsNotifier = MockUserStatsNotifier();

    // Use desktop-sized viewport to skip EnchantedVisualizer (infinite anim)
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestableWidget(
        child: const HomeScreen(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userNameProvider.overrideWith((ref) => 'Test User'),
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStarsProvider.overrideWith((ref) => 100),
          lessonsCompletedProvider.overrideWith((ref) => 2),
          categoryNotifierProvider.overrideWith(() => categoryNotifier),
          lessonNotifierProvider.overrideWith(() => lessonNotifier),
          quizzesProvider.overrideWith(MockQuizzesNotifier.new),
          userStatsProvider.overrideWith(() => userStatsNotifier),
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
          affirmationsProvider.overrideWith(MockAffirmationsNotifier.new),
        ],
      ),
    );

    // Pump enough time to let all flutter_animate one-shot animations complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Johar, Test User!'), findsOneWidget);
    expect(find.text('Daily Progress: 0%'), findsNothing);
  });

  group('continueLessonFor', () {
    const lessons = [
      LessonEntity(
        id: 'lesson_numbers',
        categoryId: 'numbers',
        titleOlChiki: '᱑',
        titleLatin: 'Numbers',
      ),
      LessonEntity(
        id: 'lesson_letters',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Letters',
      ),
      LessonEntity(
        id: 'lesson_words',
        categoryId: 'words',
        titleOlChiki: 'ᱟ',
        titleLatin: 'Words',
      ),
    ];

    test('prefers the last opened unfinished lesson', () {
      final result = continueLessonFor(
        lessons: lessons,
        completedLessonIds: const {},
        lastOpenedLessonId: 'lesson_words',
      );

      expect(result?.id, 'lesson_words');
    });

    test('falls back when the last opened lesson is completed', () {
      final result = continueLessonFor(
        lessons: lessons,
        completedLessonIds: const {'lesson_words'},
        lastOpenedLessonId: 'lesson_words',
      );

      expect(result?.id, 'lesson_numbers');
    });
  });
}
