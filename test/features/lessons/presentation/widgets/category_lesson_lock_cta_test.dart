import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/category_lessons/category_lesson_card.dart';

void main() {
  Widget host({required VoidCallback onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: CategoryLessonCard(
          lesson: const LessonEntity(
            id: 'lesson_2',
            categoryId: 'category_1',
            titleOlChiki: 'Two',
            titleLatin: 'Lesson Two',
            order: 2,
          ),
          primaryTitle: 'Lesson Two',
          secondaryTitle: '',
          scriptMode: 'latin',
          isDark: false,
          index: 1,
          onTap: onTap,
          gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
          themeColor: Colors.green,
          isLocked: true,
        ),
      ),
    );
  }

  testWidgets('tapping the lock CTA circle fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(onTap: () => taps++));
    await tester.pump();

    // The prominent lock badge on the card edge, not just the card body.
    await tester.tap(find.byIcon(Icons.lock_rounded));
    await tester.pump();

    expect(taps, 1);
  });
}
