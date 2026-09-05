import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/home/presentation/widgets/next_best_action_card.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mid-journey learner so the card takes its default "continue" path.
class _MidJourneyStats extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {'alphabet_intro', 'number_intro'},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 30,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 120,
    ),
  );
}

class _NoMistakes extends MistakeNotifier {
  @override
  List<MistakeItem> build() => [];
}

class _DoneMission extends LessonCompletedTodayNotifier {
  @override
  bool build() => true;
}

class _QuizDoneMission extends QuizTakenTodayNotifier {
  @override
  bool build() => true;
}

class _BakhedDoneMission extends BakhedListenedTodayNotifier {
  @override
  bool build() => true;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Animate.restartOnHotReload = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CTA exposes exactly one button to screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStatsProvider.overrideWith(_MidJourneyStats.new),
          mistakeProvider.overrideWith(_NoMistakes.new),
          lessonCompletedTodayProvider.overrideWith(_DoneMission.new),
          quizTakenTodayProvider.overrideWith(_QuizDoneMission.new),
          bakhedListenedTodayProvider.overrideWith(_BakhedDoneMission.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NextBestActionCard(nextLessonId: 'lesson_x')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // One tappable for one action: no nested wrapper button around the CTA.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NextBestActionCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && (widget.properties.button ?? false),
        ),
      ),
      findsOneWidget,
      reason: 'nested tappables announce duplicate actions to screen readers',
    );
  });
}
