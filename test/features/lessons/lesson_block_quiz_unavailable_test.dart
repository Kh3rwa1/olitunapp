import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_block_detail/lesson_block_item_view.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lesson = LessonEntity(
  id: 'lesson_1',
  categoryId: 'cat_1',
  titleOlChiki: 'ᱚ',
  titleLatin: 'Lesson 1',
);

Widget _host({
  required LessonBlockEntity block,
  required List<Override> overrides,
  required void Function() onDismiss,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LessonBlockItemView(
          block: block,
          index: 0,
          accentColor: Colors.green,
          isDark: false,
          lesson: _lesson,
          isDismissedQuiz: false,
          isAudioPlaying: false,
          playingId: null,
          onPlayAudio: (_, _) {},
          onDismissQuiz: onDismiss,
          visualMediaUrl: null,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Animate.restartOnHotReload = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty quiz reference explains and offers skip', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _host(
        block: const LessonBlockEntity(type: 'quiz', data: {}),
        overrides: [
          quizzesByIdProvider.overrideWithValue(const AsyncValue.data({})),
        ],
        onDismiss: () => dismissed = true,
      ),
    );
    await tester.pump();

    // No blank page: localized explanation plus a skip action.
    expect(find.text('No questions yet'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    expect(dismissed, isTrue);
  });

  testWidgets('unknown quiz id explains and offers skip', (tester) async {
    await tester.pumpWidget(
      _host(
        block: const LessonBlockEntity(
          type: 'quiz',
          data: {'quizId': 'quiz_missing'},
        ),
        overrides: [
          quizzesByIdProvider.overrideWithValue(const AsyncValue.data({})),
        ],
        onDismiss: () {},
      ),
    );
    await tester.pump();

    expect(find.text('No questions yet'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('quiz load error explains and offers retry + skip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        block: const LessonBlockEntity(
          type: 'quiz',
          data: {'quizId': 'quiz_1'},
        ),
        overrides: [
          quizzesByIdProvider.overrideWithValue(
            AsyncValue.error(Exception('offline'), StackTrace.empty),
          ),
        ],
        onDismiss: () {},
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong!'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('known quiz still renders its start action', (tester) async {
    await tester.pumpWidget(
      _host(
        block: const LessonBlockEntity(
          type: 'quiz',
          data: {'quizId': 'quiz_1'},
        ),
        overrides: [
          quizzesByIdProvider.overrideWithValue(
            AsyncValue.data({
              'quiz_1': QuizModel(id: 'quiz_1', title: 'First quiz'),
            }),
          ),
        ],
        onDismiss: () {},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('TAKE THE QUIZ'), findsOneWidget);
    expect(find.text('No questions yet'), findsNothing);
    expect(find.text('Something went wrong!'), findsNothing);
  });
}
