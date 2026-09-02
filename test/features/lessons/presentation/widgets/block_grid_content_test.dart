import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
// ignore: unnecessary_import
import 'package:itun/features/lessons/presentation/widgets/lesson_content/block_grid_content.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content_widgets.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

const _textBlockA = LessonBlockEntity(
  type: 'text',
  textOlChiki: 'ᱚ',
  textLatin: 'a',
);
const _textBlockB = LessonBlockEntity(
  type: 'text',
  textOlChiki: 'ᱛ',
  textLatin: 't',
);

LessonEntity _lesson(String id, List<LessonBlockEntity> blocks) => LessonEntity(
  id: id,
  categoryId: 'letters',
  titleOlChiki: 'ᱚᱠᱷᱚᱨ',
  titleLatin: 'Letters',
  blocks: blocks,
);

Future<void> pumpGrid(
  WidgetTester tester, {
  required String categoryId,
  required List<LessonBlockEntity> blocks,
  LessonEntity? lesson,
}) async {
  final router = GoRouter(
    initialLocation: '/grid',
    routes: [
      GoRoute(
        path: '/grid',
        builder: (context, state) => Scaffold(
          body: BlockGridContent(
            lessonId: 'lesson_1',
            blocks: blocks,
            categoryId: categoryId,
          ),
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId/block/:index',
        builder: (context, state) => Text(
          'block:${state.pathParameters['lessonId']}:${state.pathParameters['index']}',
        ),
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
        learnerLessonsProvider.overrideWithValue(
          AsyncValue.data(lesson == null ? <LessonEntity>[] : [lesson]),
        ),
        learnerLettersProvider.overrideWithValue(const AsyncValue.data([])),
        learnerWordsProvider.overrideWithValue(const AsyncValue.data([])),
        learnerNumbersProvider.overrideWithValue(const AsyncValue.data([])),
        learnerSentencesProvider.overrideWithValue(const AsyncValue.data([])),
        effectiveScriptModeProvider.overrideWithValue('both'),
        effectiveTeachingLanguageProvider.overrideWithValue('en'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty placeholder when the lesson has no blocks', (
    tester,
  ) async {
    await pumpGrid(
      tester,
      categoryId: 'letters',
      blocks: const [],
      lesson: _lesson('lesson_1', const []),
    );

    expect(
      find.text('No items in this lesson. Add content blocks in admin.'),
      findsOneWidget,
    );
  });

  testWidgets('renders one grid cell per block', (tester) async {
    await pumpGrid(
      tester,
      categoryId: 'letters',
      blocks: const [_textBlockA, _textBlockB],
      lesson: _lesson('lesson_1', const [_textBlockA, _textBlockB]),
    );

    expect(find.byType(DynamicBlockGridCell), findsNWidgets(2));
    expect(find.text('ᱚ'), findsOneWidget);
    expect(find.text('ᱛ'), findsOneWidget);
  });

  testWidgets('tapping a cell falls back to the block index route', (
    tester,
  ) async {
    await pumpGrid(
      tester,
      categoryId: 'letters',
      blocks: const [_textBlockA],
      lesson: _lesson('lesson_1', const [_textBlockA]),
    );

    await tester.tap(find.text('ᱚ'));
    await tester.pumpAndSettle();

    expect(find.text('block:lesson_1:0'), findsOneWidget);
  });

  testWidgets('alphabet categories keep cells interactive in grid layout', (
    tester,
  ) async {
    await pumpGrid(
      tester,
      categoryId: 'cat_alphabets',
      blocks: const [_textBlockA, _textBlockB],
      lesson: _lesson('lesson_1', const [_textBlockA, _textBlockB]),
    );

    expect(find.byType(BlockGridContent), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('sentence categories render cells for phrase blocks', (
    tester,
  ) async {
    const phrase = LessonBlockEntity(
      type: 'text',
      textOlChiki: 'ᱡᱚᱦᱟᱨ',
      textLatin: 'johar',
    );
    await pumpGrid(
      tester,
      categoryId: 'sentences',
      blocks: const [phrase],
      lesson: _lesson('lesson_1', const [phrase]),
    );

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
  });
}
