import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/lesson_detail_screen.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/models/content_models.dart';
import '../../test_utils.dart';

class MockLessonRepository extends Mock implements LessonRepository {}

class _MockLessonNotifier extends LessonNotifier {
  final AsyncValue<List<LessonEntity>> mockState;

  _MockLessonNotifier(this.mockState, LessonRepository repo) : super(repo) {
    state = mockState;
  }

  @override
  Future<void> loadLessons() async {}
}

class _MockUserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>>
    with Mock
    implements UserStatsNotifier {
  _MockUserStatsNotifier()
    : super(
        const AsyncValue.data(
          UserStatsEntity(
            practicedLetters: {},
            completedLessons: {},
            quizHistory: {},
            categoryMastery: {},
            totalLearningMinutes: 0,
            lastActiveDate: '',
            currentStreak: 0,
            totalStars: 0,
          ),
        ),
      );
}

void main() {
  late MockLessonRepository mockRepo;

  setUp(() {
    mockRepo = MockLessonRepository();
  });

  const mockLesson = LessonEntity(
    id: 'test_lesson_1',
    categoryId: 'alphabets',
    titleOlChiki: 'ᱚ',
    titleLatin: 'Lesson 1',
    description: 'Learn the first letter',
    blocks: [
      LessonBlockEntity(
        type: 'text',
        textOlChiki: 'ᱚ',
        textLatin: 'This is the first letter of Ol Chiki.',
      ),
    ],
  );

  testWidgets('LessonDetailScreen shows loading state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      createTestableWidget(
        child: const LessonDetailScreen(lessonId: 'test_lesson_1'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith((ref) => _MockUserStatsNotifier()),
          lessonNotifierProvider.overrideWith(
            (ref) => _MockLessonNotifier(const AsyncValue.loading(), mockRepo),
          ),
          lettersProvider.overrideWith((ref) => MockLettersNotifier()),
          numbersProvider.overrideWith((ref) => MockNumbersNotifier()),
          wordsProvider.overrideWith((ref) => MockWordsNotifier()),
          sentencesProvider.overrideWith((ref) => MockSentencesNotifier()),
        ],
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LessonDetailScreen shows lesson content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      createTestableWidget(
        child: const LessonDetailScreen(lessonId: 'test_lesson_1'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith((ref) => _MockUserStatsNotifier()),
          lessonNotifierProvider.overrideWith(
            (ref) => _MockLessonNotifier(
              const AsyncValue.data([mockLesson]),
              mockRepo,
            ),
          ),
          lettersProvider.overrideWith((ref) => MockLettersNotifier()),
          numbersProvider.overrideWith((ref) => MockNumbersNotifier()),
          wordsProvider.overrideWith((ref) => MockWordsNotifier()),
          sentencesProvider.overrideWith((ref) => MockSentencesNotifier()),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lesson 1'), findsOneWidget);
    expect(find.text('This is the first letter of Ol Chiki.'), findsOneWidget);
  });

  testWidgets(
    'LessonDetailScreen shows a not found state for unknown lessons',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        createTestableWidget(
          child: const LessonDetailScreen(lessonId: 'missing_lesson'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userStatsProvider.overrideWith((ref) => _MockUserStatsNotifier()),
            lessonNotifierProvider.overrideWith(
              (ref) => _MockLessonNotifier(
                const AsyncValue.data([mockLesson]),
                mockRepo,
              ),
            ),
            lettersProvider.overrideWith((ref) => MockLettersNotifier()),
            numbersProvider.overrideWith((ref) => MockNumbersNotifier()),
            wordsProvider.overrideWith((ref) => MockWordsNotifier()),
            sentencesProvider.overrideWith((ref) => MockSentencesNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lesson not found'), findsOneWidget);
      expect(find.text('Lesson 1'), findsNothing);
    },
  );
}

class MockLettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>>
    with Mock
    implements LettersNotifier {
  MockLettersNotifier() : super(const AsyncValue.data([]));
}

class MockNumbersNotifier extends StateNotifier<AsyncValue<List<NumberModel>>>
    with Mock
    implements NumbersNotifier {
  MockNumbersNotifier() : super(const AsyncValue.data([]));
}

class MockWordsNotifier extends StateNotifier<AsyncValue<List<WordModel>>>
    with Mock
    implements WordsNotifier {
  MockWordsNotifier() : super(const AsyncValue.data([]));
}

class MockSentencesNotifier
    extends StateNotifier<AsyncValue<List<SentenceModel>>>
    with Mock
    implements SentencesNotifier {
  MockSentencesNotifier() : super(const AsyncValue.data([]));
}
