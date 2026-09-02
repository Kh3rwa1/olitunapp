import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/vocabulary_list_content.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

const _lesson = LessonEntity(
  id: 'lesson_1',
  categoryId: 'words',
  titleOlChiki: '',
  titleLatin: 'Greetings',
  blocks: [LessonBlockEntity(type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ')],
);

Future<void> pumpWords(
  WidgetTester tester,
  List<WordModel> words, {
  LessonEntity? lesson = _lesson,
  LessonLayoutMode layoutMode = LessonLayoutMode.list,
  String teachingLanguage = 'en',
}) async {
  final router = GoRouter(
    initialLocation: '/content',
    routes: [
      GoRoute(
        path: '/content',
        builder: (context, state) =>
            const Scaffold(body: VocabularyListContent(lessonId: 'lesson_1')),
      ),
      GoRoute(
        path: '/word/:lessonId/:id',
        builder: (context, state) => Text('word:${state.pathParameters['id']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerWordsProvider.overrideWithValue(AsyncValue.data(words)),
        learnerLessonsProvider.overrideWithValue(
          AsyncValue.data(lesson == null ? <LessonEntity>[] : [lesson]),
        ),
        effectiveTeachingLanguageProvider.overrideWithValue(teachingLanguage),
        effectiveScriptModeProvider.overrideWithValue('both'),
        lessonLayoutModeProvider.overrideWith((ref) => layoutMode),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final words = [
    WordModel(
      id: 'word_johar',
      wordOlChiki: 'ᱡᱚᱦᱟᱨ',
      wordLatin: 'johar',
      meaning: 'hello',
      pronunciation: 'jo-har',
      order: 1,
    ),
    WordModel(
      id: 'word_other',
      wordOlChiki: 'ᱵᱟᱭ',
      wordLatin: 'bai',
      meaning: 'no',
      order: 2,
    ),
  ];

  testWidgets('list mode shows scoped word cards with pronunciation chip', (
    tester,
  ) async {
    await pumpWords(tester, words);

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
    expect(find.text('johar'), findsOneWidget);
    expect(find.text('[jo-har]'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('bai'), findsNothing);
  });

  testWidgets('grid mode renders one card per scoped word', (tester) async {
    await pumpWords(tester, words, layoutMode: LessonLayoutMode.grid);

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
    expect(find.text('[jo-har]'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('hides pronunciation outside English teaching language', (
    tester,
  ) async {
    await pumpWords(tester, words, teachingLanguage: 'hi');

    expect(find.text('[jo-har]'), findsNothing);
    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
  });

  testWidgets('shows placeholder when lesson is not loaded', (tester) async {
    await pumpWords(tester, words, lesson: null);

    expect(
      find.text('No words in this lesson. Add content blocks in admin.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a word card navigates to its detail route', (
    tester,
  ) async {
    await pumpWords(tester, words);

    await tester.tap(find.text('ᱡᱚᱦᱟᱨ'));
    await tester.pumpAndSettle();

    expect(find.text('word:word_johar'), findsOneWidget);
  });
}
