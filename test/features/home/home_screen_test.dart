import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/home/presentation/home_screen.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/models/content_models.dart';
import '../../test_utils.dart';

class MockCategoryNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>>
    with Mock
    implements CategoryNotifier {
  MockCategoryNotifier() : super(const AsyncValue.data([]));
}

class MockLessonNotifier extends StateNotifier<AsyncValue<List<LessonEntity>>>
    with Mock
    implements LessonNotifier {
  MockLessonNotifier() : super(const AsyncValue.data([]));
}

class MockQuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>>
    with Mock
    implements QuizzesNotifier {
  MockQuizzesNotifier() : super(const AsyncValue.data([]));
}

class MockBannersNotifier
    extends StateNotifier<AsyncValue<List<FeaturedBannerModel>>>
    with Mock
    implements BannersNotifier {
  MockBannersNotifier() : super(const AsyncValue.data([]));
}

class MockUserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>>
    with Mock
    implements UserStatsNotifier {
  MockUserStatsNotifier()
    : super(
        const AsyncValue.data(
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
        ),
      );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable flutter_animate effects in tests to prevent pending timers
    Animate.restartOnHotReload = false;
  });

  testWidgets('HomeScreen renders greeting and daily progress', (tester) async {
    // Use desktop-sized viewport to skip EnchantedVisualizer (infinite anim)
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestableWidget(
        child: const HomeScreen(),
        overrides: [
          userNameProvider.overrideWith((ref) => 'Test User'),
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStarsProvider.overrideWith((ref) => 100),
          lessonsCompletedProvider.overrideWith((ref) => 2),
          categoryNotifierProvider.overrideWith(
            (ref) => MockCategoryNotifier(),
          ),
          lessonNotifierProvider.overrideWith((ref) => MockLessonNotifier()),
          quizzesProvider.overrideWith((ref) => MockQuizzesNotifier()),
          userStatsProvider.overrideWith((ref) => MockUserStatsNotifier()),
          bannersProvider.overrideWith((ref) => MockBannersNotifier()),
        ],
      ),
    );

    // Pump enough time to let all flutter_animate one-shot animations complete
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Johar, Test User!'), findsOneWidget);
    expect(find.text('Daily Progress: 0%'), findsOneWidget);
  });
}
