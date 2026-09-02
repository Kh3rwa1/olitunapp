import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/dynamic_block_grid_cell.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';

const _letterBlock = LessonBlockEntity(
  type: 'text',
  textOlChiki: 'ᱚ',
  textLatin: 'a',
);
const _dashBlock = LessonBlockEntity(type: 'text', textOlChiki: 'ᱚ - ᱛ');
const _plainBlock = LessonBlockEntity(type: 'text', textOlChiki: 'zzz');

LessonEntity _lesson(List<LessonBlockEntity> blocks) => LessonEntity(
  id: 'lesson_1',
  categoryId: 'letters',
  titleOlChiki: 'ᱚᱠᷚᱨ',
  titleLatin: 'Letters',
  blocks: blocks,
);

Future<void> pumpCell(
  WidgetTester tester,
  LessonBlockEntity block, {
  List<LetterModel> letters = const [],
  List<NumberModel> numbers = const [],
  List<WordModel> words = const [],
  List<SentenceModel> sentences = const [],
  List<LessonBlockEntity> lessonBlocks = const [],
  bool isAlphabet = true,
}) async {
  final router = GoRouter(
    initialLocation: '/cell',
    routes: [
      GoRoute(
        path: '/cell',
        builder: (context, state) => Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: DynamicBlockGridCell(
              lessonId: 'lesson_1',
              block: block,
              isAlphabet: isAlphabet,
              isNumber: false,
              isSentence: false,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/letter/:lessonId/:char',
        builder: (context, state) =>
            Text('letter:${state.pathParameters['char']}'),
      ),
      GoRoute(
        path: '/number/:lessonId/:id',
        builder: (context, state) =>
            Text('number:${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/word/:lessonId/:id',
        builder: (context, state) => Text('word:${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/sentence/:lessonId/:id',
        builder: (context, state) =>
            Text('sentence:${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/lesson/:lessonId/block/:index',
        builder: (context, state) =>
            Text('block:${state.pathParameters['index']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerLettersProvider.overrideWithValue(AsyncValue.data(letters)),
        learnerNumbersProvider.overrideWithValue(AsyncValue.data(numbers)),
        learnerWordsProvider.overrideWithValue(AsyncValue.data(words)),
        learnerSentencesProvider.overrideWithValue(AsyncValue.data(sentences)),
        learnerLessonsProvider.overrideWithValue(
          AsyncValue.data([_lesson(lessonBlocks)]),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'resolves an exact letter match and navigates to the letter route',
    (tester) async {
      await pumpCell(
        tester,
        _letterBlock,
        letters: [
          LetterModel(
            id: 'letter_a',
            charOlChiki: 'ᱚ',
            transliterationLatin: 'a',
          ),
        ],
      );

      expect(find.text('ᱚ'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('ᱚ'));
      await tester.pumpAndSettle();

      expect(find.text('letter:ᱚ'), findsOneWidget);
    },
  );

  testWidgets('splits dash-separated text and matches the first part', (
    tester,
  ) async {
    await pumpCell(
      tester,
      _dashBlock,
      letters: [
        LetterModel(
          id: 'letter_t',
          charOlChiki: 'ᱛ',
          transliterationLatin: 't',
        ),
      ],
    );

    await tester.tap(find.text('ᱚ - ᱛ'));
    await tester.pumpAndSettle();

    expect(find.text('letter:ᱛ'), findsOneWidget);
  });

  testWidgets('matches numbers, words and sentences in order', (tester) async {
    await pumpCell(
      tester,
      const LessonBlockEntity(type: 'text', textOlChiki: '᱑'),
      numbers: [
        NumberModel(
          id: 'num_1',
          numeral: '᱑',
          value: 1,
          nameOlChiki: 'ᱢᱤᱛ',
          nameLatin: 'mit',
        ),
      ],
    );

    await tester.tap(find.text('᱑'));
    await tester.pumpAndSettle();

    expect(find.text('number:num_1'), findsOneWidget);
  });

  testWidgets('matches a word by its Ol Chiki text', (tester) async {
    await pumpCell(
      tester,
      const LessonBlockEntity(type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ'),
      words: [
        WordModel(
          id: 'word_johar',
          wordOlChiki: 'ᱡᱚᱦᱟᱨ',
          wordLatin: 'johar',
          meaning: 'hello',
        ),
      ],
    );

    await tester.tap(find.text('ᱡᱚᱦᱟᱨ'));
    await tester.pumpAndSettle();

    expect(find.text('word:word_johar'), findsOneWidget);
  });

  testWidgets('falls back to the block index route when nothing matches', (
    tester,
  ) async {
    await pumpCell(tester, _plainBlock, lessonBlocks: const [_plainBlock]);

    await tester.tap(find.text('zzz'));
    await tester.pumpAndSettle();

    expect(find.text('block:0'), findsOneWidget);
  });

  testWidgets('shows the meaning from the block data payload', (tester) async {
    await pumpCell(
      tester,
      const LessonBlockEntity(
        type: 'text',
        textOlChiki: 'zzz',
        data: {'meaning': 'a meaning'},
      ),
      lessonBlocks: const [_plainBlock],
      isAlphabet: false,
    );

    expect(find.text('a meaning'), findsOneWidget);
  });
}
