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
import 'package:itun/core/ads/widgets/native_ad_widget.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/features/home/presentation/widgets/home_content_grid.dart';
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
          contentListProvider((
            ContentKind.lesson,
            null,
          )).overrideWith((ref) async => []),
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
        ],
      ),
    );

    // Pump enough time to let all flutter_animate one-shot animations complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Johar, Test User!'), findsOneWidget);
    expect(find.text('Daily Progress: 0%'), findsNothing);
    final ad = find.byType(NativeAdWidget);
    expect(ad, findsOneWidget);
    expect(find.byType(BannerAdWidget), findsNothing);
    expect(
      tester.getTopLeft(find.byType(HomeContentGrid)).dy,
      lessThan(tester.getTopLeft(ad).dy),
    );
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

    test(
      'resolves a locked lastOpenedLesson to its blocking prerequisite so user starts what is not finished',
      () {
        const vocabLessons = [
          LessonEntity(
            id: 'lesson_vocab_basics',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱡᱚᱦᱟᱨ',
            titleLatin: 'Greetings & Basics',
          ),
          LessonEntity(
            id: 'lesson_vocab_family',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱜᱷᱟᱨᱚᱸᱡᱽ',
            titleLatin: 'Family',
            order: 1,
          ),
          LessonEntity(
            id: 'lesson_vocab_daily',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱵᱮᱵᱷᱟᱨ ᱨᱚᱲ',
            titleLatin: 'Daily Use Words',
            order: 2,
          ),
          LessonEntity(
            id: 'lesson_vocab_colors',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱨᱚᱝ',
            titleLatin: 'Colors',
            order: 3,
          ),
        ];

        // User completed basics and family, but not daily.
        // If lastOpenedLessonId points to colors (locked), continueLessonFor
        // must NOT return colors — it must return the blocking lesson 'lesson_vocab_daily'!
        final result = continueLessonFor(
          lessons: vocabLessons,
          completedLessonIds: const {
            'lesson_vocab_basics',
            'lesson_vocab_family',
          },
          lastOpenedLessonId: 'lesson_vocab_colors',
        );

        expect(result?.id, 'lesson_vocab_daily');
      },
    );

    test(
      'starts the next unlocked lesson when earlier lessons are completed',
      () {
        const vocabLessons = [
          LessonEntity(
            id: 'lesson_vocab_basics',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱡᱚᱦᱟᱨ',
            titleLatin: 'Greetings & Basics',
          ),
          LessonEntity(
            id: 'lesson_vocab_family',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱜᱷᱟᱨᱚᱸᱡᱽ',
            titleLatin: 'Family',
            order: 1,
          ),
          LessonEntity(
            id: 'lesson_vocab_daily',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱵᱮᱵᱷᱟᱨ ᱨᱚᱲ',
            titleLatin: 'Daily Use Words',
            order: 2,
          ),
          LessonEntity(
            id: 'lesson_vocab_colors',
            categoryId: 'cat_vocab',
            titleOlChiki: 'ᱨᱚᱝ',
            titleLatin: 'Colors',
            order: 3,
          ),
        ];

        final result = continueLessonFor(
          lessons: vocabLessons,
          completedLessonIds: const {
            'lesson_vocab_basics',
            'lesson_vocab_family',
            'lesson_vocab_daily',
          },
        );

        expect(result?.id, 'lesson_vocab_colors');
      },
    );

    test('respects category order and never returns a locked lesson', () {
      const allLessons = [
        LessonEntity(
          id: 'lesson_letters_1',
          categoryId: 'cat_alphabets',
          titleOlChiki: 'ᱚ',
          titleLatin: 'Letter 1',
        ),
        LessonEntity(
          id: 'lesson_letters_2',
          categoryId: 'cat_alphabets',
          titleOlChiki: 'ᱛ',
          titleLatin: 'Letter 2',
          order: 1,
        ),
        LessonEntity(
          id: 'lesson_vocab_1',
          categoryId: 'cat_vocab',
          titleOlChiki: 'ᱥᱟᱹᱵᱟᱹᱫᱽ',
          titleLatin: 'Vocab 1',
        ),
      ];

      const categories = [
        CategoryEntity(
          id: 'cat_alphabets',
          titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
          titleLatin: 'Alphabets',
        ),
        CategoryEntity(
          id: 'cat_vocab',
          titleOlChiki: 'ᱥᱟᱹᱵᱟᱹᱫᱽ',
          titleLatin: 'Vocabulary',
          order: 1,
        ),
      ];

      // Alphabet 1 complete -> Alphabet 2 is next
      final result1 = continueLessonFor(
        lessons: allLessons,
        completedLessonIds: const {'lesson_letters_1'},
        categories: categories,
      );
      expect(result1?.id, 'lesson_letters_2');

      // Alphabet 1 & 2 complete -> Vocab 1 is next
      final result2 = continueLessonFor(
        lessons: allLessons,
        completedLessonIds: const {'lesson_letters_1', 'lesson_letters_2'},
        categories: categories,
      );
      expect(result2?.id, 'lesson_vocab_1');

      // All complete -> returns null
      final result3 = continueLessonFor(
        lessons: allLessons,
        completedLessonIds: const {
          'lesson_letters_1',
          'lesson_letters_2',
          'lesson_vocab_1',
        },
        categories: categories,
      );
      expect(result3, isNull);
    });
  });
}
