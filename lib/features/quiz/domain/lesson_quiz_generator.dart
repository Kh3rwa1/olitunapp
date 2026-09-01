import '../../../shared/models/content_models.dart';
import '../../lessons/domain/entities/lesson_entity.dart';

class LessonQuizGenerator {
  const LessonQuizGenerator._();

  static QuizModel generate(LessonEntity lesson) {
    final questions = <QuizQuestion>[];
    final blocks = lesson.blocks.where((b) => b.type != 'quiz').toList();

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final olChiki = block.textOlChiki?.trim();
      final latin = block.textLatin?.trim();

      if (olChiki == null ||
          olChiki.isEmpty ||
          latin == null ||
          latin.isEmpty) {
        continue;
      }

      // 1. Gather other items in the same lesson as high-quality distractors
      final otherBlockTranslations = blocks
          .where(
            (b) =>
                b.textLatin != null &&
                b.textLatin!.trim().isNotEmpty &&
                b.textLatin!.trim() != latin,
          )
          .map((b) => b.textLatin!.trim())
          .toSet()
          .toList();

      // 2. Fallback general distractors based on the category type
      final isNumberCategory = lesson.categoryId.toLowerCase().contains(
        'number',
      );
      final defaultDistractors = isNumberCategory
          ? ['1', '2', '3', '4', '5', '6', '7', '8', '9']
          : [
              'At',
              'Ot',
              'It',
              'Et',
              'hand',
              'leg',
              'head',
              'eye',
              'water',
              'food',
              'house',
              'tree',
            ];

      final distractors = [
        ...otherBlockTranslations,
        ...defaultDistractors,
      ].where((d) => d != latin).toList()..shuffle();

      final options = [latin, ...distractors.take(3)]..shuffle();
      final correctIndex = options.indexOf(latin);

      final promptLatin = isNumberCategory
          ? 'Identify this number:'
          : (lesson.categoryId.toLowerCase().contains('alphabet')
                ? 'Which sound does this letter make?'
                : 'Choose the correct English meaning:');

      questions.add(
        QuizQuestion(
          promptOlChiki: olChiki,
          promptLatin: promptLatin,
          optionsOlChiki: options,
          optionsLatin: options,
          correctIndex: correctIndex,
          audioUrl: block.audioUrl,
        ),
      );
    }

    // Fallback: If no interactive blocks could be extracted, generate a lesson-title question
    if (questions.isEmpty) {
      questions.add(
        QuizQuestion(
          promptOlChiki: lesson.titleOlChiki,
          promptLatin: 'Choose the correct English title for this lesson:',
          optionsOlChiki: [
            lesson.titleLatin,
            'Other Lesson',
            'Practice',
            'Review',
          ],
          optionsLatin: [
            lesson.titleLatin,
            'Other Lesson',
            'Practice',
            'Review',
          ],
        ),
      );
    }

    return QuizModel(
      id: 'dynamic_quiz_${lesson.id}',
      categoryId: lesson.categoryId,
      title: '${lesson.titleLatin} Quiz',
      questions: questions.take(10).toList(),
    );
  }
}
