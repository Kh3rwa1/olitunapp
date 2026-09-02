import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/empty_content_placeholder.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/number_grid_content.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';

final allNumbers = [
  NumberModel(
    id: 'num_1',
    numeral: '᱑',
    value: 1,
    nameOlChiki: 'ᱢᱤᱛ',
    nameLatin: 'mit',
    order: 1,
  ),
  NumberModel(
    id: 'num_12',
    numeral: '᱑᱒',
    value: 12,
    nameOlChiki: 'ᱜᱮᱞ ᱢᱤᱫ',
    nameLatin: 'gel mit',
    order: 2,
  ),
  NumberModel(
    id: 'num_120',
    numeral: '᱑᱒᱐',
    value: 120,
    nameOlChiki: 'ᱥᱟᱭ ᱜᱮᱥᱟᱭ',
    nameLatin: 'say gesay',
    order: 3,
  ),
  NumberModel(
    id: 'num_inactive',
    numeral: '᱙',
    value: 9,
    nameOlChiki: 'ᱜᱮᱭᱟ',
    nameLatin: 'gaya',
    isActive: false,
  ),
];

Future<void> pumpNumbers(
  WidgetTester tester, {
  required LessonEntity lesson,
  List<NumberModel>? numbers,
}) async {
  final router = GoRouter(
    initialLocation: '/grid',
    routes: [
      GoRoute(
        path: '/grid',
        builder: (context, state) =>
            const Scaffold(body: NumberGridContent(lessonId: 'lesson_1')),
      ),
      GoRoute(
        path: '/number/:lessonId/:id',
        builder: (context, state) =>
            Text('number:${state.pathParameters['id']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerNumbersProvider.overrideWithValue(
          AsyncValue.data(numbers ?? allNumbers),
        ),
        learnerLessonsProvider.overrideWithValue(AsyncValue.data([lesson])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scopes numbers matched by lesson block text', (tester) async {
    await pumpNumbers(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_1',
        categoryId: 'numbers',
        titleOlChiki: '',
        titleLatin: 'Numbers',
        blocks: [LessonBlockEntity(type: 'text', textOlChiki: '᱑')],
      ),
    );

    expect(find.text('mit'), findsOneWidget);
    expect(find.text('gel mit'), findsNothing);
  });

  testWidgets('falls back to title range for lessons without text blocks', (
    tester,
  ) async {
    await pumpNumbers(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_1',
        categoryId: 'numbers',
        titleOlChiki: '',
        titleLatin: 'Numbers 0-9',
      ),
    );

    expect(find.text('mit'), findsOneWidget);
    expect(find.text('gel mit'), findsNothing);
    expect(find.text('say gesay'), findsNothing);
  });

  testWidgets('tens range fallback matches 10-99 lessons', (tester) async {
    await pumpNumbers(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_1',
        categoryId: 'numbers',
        titleOlChiki: '',
        titleLatin: 'Tens lesson',
      ),
    );

    expect(find.text('gel mit'), findsOneWidget);
    expect(find.text('mit'), findsNothing);
  });

  testWidgets('hundred range fallback matches large-number lessons', (
    tester,
  ) async {
    await pumpNumbers(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_1',
        categoryId: 'numbers',
        titleOlChiki: '',
        titleLatin: 'Hundreds',
      ),
    );

    expect(find.text('say gesay'), findsOneWidget);
    expect(find.text('gel mit'), findsNothing);
  });

  testWidgets('tapping a number navigates to its detail route', (tester) async {
    await pumpNumbers(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_1',
        categoryId: 'numbers',
        titleOlChiki: '',
        titleLatin: 'Numbers 0-9',
      ),
    );

    await tester.tap(find.text('mit'));
    await tester.pumpAndSettle();

    expect(find.text('number:num_1'), findsOneWidget);
  });

  testWidgets('missing lesson shows the empty placeholder', (tester) async {
    final router = GoRouter(
      initialLocation: '/grid',
      routes: [
        GoRoute(
          path: '/grid',
          builder: (context, state) =>
              const Scaffold(body: NumberGridContent(lessonId: 'lesson_1')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerNumbersProvider.overrideWithValue(AsyncValue.data(allNumbers)),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data(<LessonEntity>[]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyContentPlaceholder), findsOneWidget);
    expect(find.text('᱑'), findsNothing);
  });
}
