import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/empty_content_placeholder.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/letter_grid_content.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';

const _lesson = LessonEntity(
  id: 'lesson_1',
  categoryId: 'letters',
  titleOlChiki: 'ᱚᱠᷚᱨ',
  titleLatin: 'Letters',
  blocks: [LessonBlockEntity(type: 'text', textOlChiki: 'ᱚ ᱛ')],
);

Future<void> pumpLetters(
  WidgetTester tester,
  List<LetterModel> letters, {
  LessonEntity? lesson = _lesson,
}) async {
  final router = GoRouter(
    initialLocation: '/grid',
    routes: [
      GoRoute(
        path: '/grid',
        builder: (context, state) =>
            const Scaffold(body: LetterGridContent(lessonId: 'lesson_1')),
      ),
      GoRoute(
        path: '/letter/:lessonId/:char',
        builder: (context, state) =>
            Text('letter:${state.pathParameters['char']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerLettersProvider.overrideWithValue(AsyncValue.data(letters)),
        learnerLessonsProvider.overrideWithValue(
          AsyncValue.data(lesson == null ? <LessonEntity>[] : [lesson]),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final letters = [
    LetterModel(
      id: 'letter_a',
      charOlChiki: 'ᱚ',
      transliterationLatin: 'a',
      order: 1,
    ),
    LetterModel(id: 'letter_t', charOlChiki: 'ᱛ', transliterationLatin: 't'),
    LetterModel(
      id: 'letter_u',
      charOlChiki: 'ᱩ',
      transliterationLatin: 'u',
      order: 2,
    ),
  ];

  testWidgets('scopes letters to the lesson blocks and sorts by order', (
    tester,
  ) async {
    await pumpLetters(tester, letters);

    expect(find.text('ᱚ'), findsOneWidget);
    expect(find.text('ᱛ'), findsOneWidget);
    expect(find.text('ᱩ'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('shows the empty placeholder when lesson is missing', (
    tester,
  ) async {
    await pumpLetters(tester, letters, lesson: null);

    expect(
      find.text('No letters in this lesson. Add content blocks in admin.'),
      findsOneWidget,
    );
  });

  testWidgets('shows placeholder when blocks reference no letters', (
    tester,
  ) async {
    const lesson = LessonEntity(
      id: 'lesson_1',
      categoryId: 'letters',
      titleOlChiki: '',
      titleLatin: 'Letters',
      blocks: [LessonBlockEntity(type: 'image', imageUrl: 'x.png')],
    );
    await pumpLetters(tester, letters, lesson: lesson);

    expect(find.byType(EmptyContentPlaceholder), findsOneWidget);
  });

  testWidgets('tapping a letter navigates to its detail route', (tester) async {
    await pumpLetters(tester, letters);

    await tester.tap(find.text('ᱛ'));
    await tester.pumpAndSettle();

    expect(find.text('letter:ᱛ'), findsOneWidget);
  });

  testWidgets(
    'tapping a letter without audio skips playback but still navigates',
    (tester) async {
      final withAudio = [
        LetterModel(
          id: 'letter_a',
          charOlChiki: 'ᱚ',
          transliterationLatin: 'a',
          order: 1,
        ),
      ];
      await pumpLetters(tester, withAudio);

      await tester.tap(find.text('ᱚ'));
      await tester.pumpAndSettle();

      expect(find.text('letter:ᱚ'), findsOneWidget);
    },
  );
}
