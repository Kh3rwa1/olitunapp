import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';

class MockUserStatsNotifier extends Mock implements UserStatsNotifier {}

class MockTypingPracticeController extends TypingPracticeController {
  final TypingPracticeState mockedState;
  final List<String> appendedChars = [];
  bool startPracticeCalled = false;
  bool deleteLastCharCalled = false;
  bool revealAndContinueCalled = false;
  bool tryAgainCalled = false;
  bool markCelebrationDoneCalled = false;

  MockTypingPracticeController(this.mockedState);

  @override
  TypingPracticeState build(TypingPracticeArgs arg) => mockedState;

  @override
  void startPractice() {
    startPracticeCalled = true;
  }

  @override
  void appendChar(String char) {
    appendedChars.add(char);
  }

  @override
  void deleteLastChar() {
    deleteLastCharCalled = true;
  }

  @override
  void revealAndContinue() {
    revealAndContinueCalled = true;
  }

  @override
  void tryAgain() {
    tryAgainCalled = true;
  }

  @override
  void markCelebrationDone() {
    markCelebrationDoneCalled = true;
  }
}

Future<void> pumpPracticeWidget(
  WidgetTester tester,
  Widget widget, {
  required TypingPracticeArgs args,
  required TypingPracticeState state,
  required MockUserStatsNotifier mockUserStats,
  SharedPreferences? prefs,
  MockTypingPracticeController? controllerOverride,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final actualPrefs = prefs ?? await SharedPreferences.getInstance();
  final controller = controllerOverride ?? MockTypingPracticeController(state);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(actualPrefs),
        userStatsProvider.overrideWith((ref) => mockUserStats),
        typingPracticeControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: widget,
        ),
      ),
    ),
  );
}
