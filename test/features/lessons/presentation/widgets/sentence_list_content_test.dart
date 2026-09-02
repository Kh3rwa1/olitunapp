import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/empty_content_placeholder.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/lesson_content_helpers.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/sentence_list_content.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

const _lesson = LessonEntity(
  id: 'lesson_1',
  categoryId: 'sentences',
  titleOlChiki: '',
  titleLatin: 'Greetings',
  blocks: [LessonBlockEntity(type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ')],
);

Future<void> pumpSentences(
  WidgetTester tester,
  List<SentenceModel> sentences, {
  LessonEntity? lesson = _lesson,
  LessonLayoutMode layoutMode = LessonLayoutMode.list,
}) async {
  final router = GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) =>
            const Scaffold(body: SentenceListContent(lessonId: 'lesson_1')),
      ),
      GoRoute(
        path: '/sentence/:lessonId/:id',
        builder: (context, state) =>
            Text('sentence:${state.pathParameters['id']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerSentencesProvider.overrideWithValue(AsyncValue.data(sentences)),
        learnerLessonsProvider.overrideWithValue(
          AsyncValue.data(lesson == null ? <LessonEntity>[] : [lesson]),
        ),
        effectiveTeachingLanguageProvider.overrideWithValue('en'),
        effectiveScriptModeProvider.overrideWithValue('both'),
        lessonLayoutModeProvider.overrideWith((ref) => layoutMode),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final sentences = [
    SentenceModel(
      id: 'sen_greet',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ',
      sentenceLatin: 'johar',
      meaning: 'hello',
      pronunciation: 'jo-har',
      order: 1,
    ),
    SentenceModel(
      id: 'sen_other',
      sentenceOlChiki: 'ᱵᱟᱭ',
      sentenceLatin: 'bai',
      meaning: 'no',
    ),
    SentenceModel(
      id: 'sen_inactive',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ',
      sentenceLatin: 'johar dup',
      meaning: 'hello',
      isActive: false,
      order: 2,
    ),
  ];

  testWidgets('list mode shows scoped sentence cards with pronunciation', (
    tester,
  ) async {
    await pumpSentences(tester, sentences);

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
    expect(find.text('Pronunciation: jo-har'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('bai'), findsNothing);
    expect(find.byType(ContentNavArrow), findsOneWidget);
  });

  testWidgets('grid mode renders one card per scoped sentence', (tester) async {
    await pumpSentences(tester, sentences, layoutMode: LessonLayoutMode.grid);

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
    expect(find.text('bai'), findsNothing);
  });

  testWidgets('shows placeholder when lesson is not loaded', (tester) async {
    await pumpSentences(tester, sentences, lesson: null);

    expect(
      find.text('No sentences in this lesson. Add content blocks in admin.'),
      findsOneWidget,
    );
  });

  testWidgets('excludes inactive sentences even when text matches', (
    tester,
  ) async {
    final onlyInactive = [
      SentenceModel(
        id: 'sen_inactive',
        sentenceOlChiki: 'ᱡᱚᱦᱟᱨ',
        sentenceLatin: 'johar dup',
        meaning: 'hello',
        isActive: false,
      ),
    ];
    await pumpSentences(tester, onlyInactive);

    expect(find.byType(EmptyContentPlaceholder), findsOneWidget);
  });

  testWidgets('tapping a sentence card navigates to its detail route', (
    tester,
  ) async {
    await pumpSentences(tester, sentences);

    await tester.tap(find.text('ᱡᱚᱦᱟᱨ'));
    await tester.pumpAndSettle();

    expect(find.text('sentence:sen_greet'), findsOneWidget);
  });
}
