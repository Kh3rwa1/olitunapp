import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_progression_provider.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a deep link cannot bypass a locked lesson', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const lessons = [
      LessonEntity(
        id: 'lesson_1',
        categoryId: 'category_1',
        titleOlChiki: 'One',
        titleLatin: 'Lesson One',
        order: 1,
      ),
      LessonEntity(
        id: 'lesson_2',
        categoryId: 'category_1',
        titleOlChiki: 'Two',
        titleLatin: 'Lesson Two',
        order: 2,
        blocks: [LessonBlockEntity(type: 'text', textLatin: 'Hidden content')],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data(lessons),
          ),
          lessonsByCategoryProvider(
            'category_1',
          ).overrideWithValue(const AsyncValue.data(lessons)),
          completedLessonIdsProvider.overrideWith((ref) => const {}),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_2',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lesson locked'), findsOneWidget);
    expect(
      find.text('Complete “Lesson One” first to unlock this lesson.'),
      findsOneWidget,
    );
    expect(find.text('Hidden content'), findsNothing);
    expect(find.byType(PageView), findsNothing);
  });
}
