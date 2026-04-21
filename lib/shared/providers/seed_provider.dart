import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../../features/rhymes/domain/rhyme_model.dart';
import 'categories_provider.dart';
import 'letters_provider.dart';
import 'lessons_provider.dart';
import 'quizzes_provider.dart';
import 'rhymes_providers.dart';

Future<void> seedAppContent(WidgetRef ref) async {
  final categoriesNotifier = ref.read(categoriesProvider.notifier);
  final lettersNotifier = ref.read(lettersProvider.notifier);
  final lessonsNotifier = ref.read(lessonsProvider.notifier);

  final alphabetsId = 'cat_alphabets_${DateTime.now().millisecondsSinceEpoch}';
  categoriesNotifier.add(CategoryModel(
    id: alphabetsId, titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ', titleLatin: 'Alphabets',
    iconName: 'alphabet', gradientPreset: 'skyBlue', order: 0,
    isActive: true, totalLessons: 5,
  ));

  final letters = [['ᱚ', 'a'], ['ᱛ', 'at'], ['ᱜ', 'ag'], ['ᱝ', 'ang'], ['ᱞ', 'al']];
  for (int i = 0; i < letters.length; i++) {
    lettersNotifier.add(LetterModel(
      id: 'letter_${i}_${DateTime.now().microsecondsSinceEpoch}',
      charOlChiki: letters[i][0], transliterationLatin: letters[i][1],
      order: i, isActive: true,
    ));
  }

  final lessonTitles = ['Basics of Ol Chiki', 'Vowels I', 'Consonants I', 'Vowels II', 'Consonants II'];
  for (int i = 0; i < lessonTitles.length; i++) {
    await lessonsNotifier.addLesson(LessonModel(
      id: 'lesson_${i}_${DateTime.now().microsecondsSinceEpoch}',
      categoryId: alphabetsId, titleOlChiki: 'ᱯᱟᱹᱴ $i',
      titleLatin: lessonTitles[i], level: 'beginner', order: i,
      isActive: true, estimatedMinutes: 5, blocks: [],
    ));
  }

  categoriesNotifier.add(CategoryModel(
    id: 'cat_numbers_${DateTime.now().millisecondsSinceEpoch}',
    titleOlChiki: 'ᱮᱞᱠᱷᱟ', titleLatin: 'Numbers',
    iconName: 'numbers', gradientPreset: 'peach', order: 1,
    isActive: true, totalLessons: 3,
  ));

  categoriesNotifier.add(CategoryModel(
    id: 'cat_phrases_${DateTime.now().millisecondsSinceEpoch}',
    titleOlChiki: 'ᱛᱮᱞᱟ ᱯᱟᱹᱨᱥᱤ', titleLatin: 'Greetings',
    iconName: 'words', gradientPreset: 'mint', order: 2,
    isActive: true, totalLessons: 4,
  ));

  final quizzesNotifier = ref.read(quizzesProvider.notifier);
  final quizId = 'quiz_basics_${DateTime.now().millisecondsSinceEpoch}';
  await quizzesNotifier.addQuiz(QuizModel(
    id: quizId, categoryId: alphabetsId, title: 'Basics Quiz', level: 'beginner',
    questions: [
      QuizQuestion(
        promptOlChiki: 'Which letter is "La"?',
        optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
        optionsLatin: ['a', 'at', 'ag', 'al'], correctIndex: 3,
      ),
    ],
  ));

  await lessonsNotifier.addLesson(LessonModel(
    id: 'lesson_quiz_demo_${DateTime.now().millisecondsSinceEpoch}',
    categoryId: alphabetsId, titleOlChiki: 'ᱠᱩᱤᱡᱽ', titleLatin: 'Quiz Demo',
    level: 'beginner', order: 99, isActive: true, estimatedMinutes: 2,
    blocks: [
      LessonBlock(type: 'text', textLatin: 'Ready to test your knowledge?', textOlChiki: 'ᱵᱤᱰᱟᱹᱣ ᱨᱮᱱᱟᱜ ᱚᱠᱛᱚ!'),
      LessonBlock(type: 'quiz', quizRefId: quizId),
    ],
  ));

  final rhymesNotifier = ref.read(rhymesProvider.notifier);
  await rhymesNotifier.addRhyme(RhymeModel(
    id: 'rhyme_hati', titleOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ', titleLatin: 'Hati Lagit',
    contentOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱹᱛᱤ...', contentLatin: 'Hati lagit hati...',
    category: 'Animal', subcategory: 'Wild Animals',
  ));

  await rhymesNotifier.addRhyme(RhymeModel(
    id: 'rhyme_buru', titleOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ', titleLatin: 'Buru Re',
    contentOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ ᱵᱩᱨᱩ...', contentLatin: 'Buru re buru...',
    category: 'Nature', subcategory: 'Mountains & Forest',
  ));
}
