import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/domain/lesson_progression.dart';

void main() {
  const lessonOne = LessonEntity(
    id: 'lesson_1',
    categoryId: 'category_1',
    titleOlChiki: 'One',
    titleLatin: 'Lesson One',
    order: 1,
  );
  const lessonTwo = LessonEntity(
    id: 'lesson_2',
    categoryId: 'category_1',
    titleOlChiki: 'Two',
    titleLatin: 'Lesson Two',
    order: 2,
  );
  const lessonThree = LessonEntity(
    id: 'lesson_3',
    categoryId: 'category_1',
    titleOlChiki: 'Three',
    titleLatin: 'Lesson Three',
    order: 3,
  );
  const inactiveLesson = LessonEntity(
    id: 'lesson_inactive',
    categoryId: 'category_1',
    titleOlChiki: 'Inactive',
    titleLatin: 'Inactive',
    isActive: false,
  );

  final orderedLessons = LessonProgression.orderedActiveLessons([
    lessonThree,
    inactiveLesson,
    lessonOne,
    lessonTwo,
  ]);

  test('orders active lessons and excludes inactive content', () {
    expect(
      orderedLessons.map((lesson) => lesson.id),
      ['lesson_1', 'lesson_2', 'lesson_3'],
    );
  });

  test('unlocks only the first incomplete lesson', () {
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: const {},
        lessonId: 'lesson_1',
      ),
      LessonProgressStatus.current,
    );
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: const {},
        lessonId: 'lesson_2',
      ),
      LessonProgressStatus.locked,
    );
  });

  test('completing a lesson unlocks the next lesson', () {
    const completed = {'lesson_1'};
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: completed,
        lessonId: 'lesson_1',
      ),
      LessonProgressStatus.completed,
    );
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: completed,
        lessonId: 'lesson_2',
      ),
      LessonProgressStatus.current,
    );
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: completed,
        lessonId: 'lesson_3',
      ),
      LessonProgressStatus.locked,
    );
  });

  test('completed legacy lessons remain replayable without skipping gaps', () {
    const completed = {'lesson_1', 'lesson_3'};
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: completed,
        lessonId: 'lesson_3',
      ),
      LessonProgressStatus.completed,
    );
    expect(
      LessonProgression.blockingLesson(
        orderedLessons: orderedLessons,
        completedLessonIds: completed,
        lessonId: 'lesson_3',
      ),
      lessonTwo,
    );
  });

  test('unknown lesson IDs fail closed', () {
    expect(
      LessonProgression.statusFor(
        orderedLessons: orderedLessons,
        completedLessonIds: const {},
        lessonId: 'missing',
      ),
      LessonProgressStatus.locked,
    );
  });
}
