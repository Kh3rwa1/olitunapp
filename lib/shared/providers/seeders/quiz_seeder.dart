import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/content_models.dart' hide CategoryModel, LessonModel;
import '../providers.dart';

class QuizSeeder {
  static Future<void> seed(WidgetRef ref, String actualAlphabetsId) async {
    const quizId = 'quiz_basics_1';
    await ref
        .read(quizzesProvider.notifier)
        .addQuiz(
          QuizModel(
            id: quizId,
            categoryId: actualAlphabetsId,
            title: 'Basics Quiz',
            questions: [
              QuizQuestion(
                promptOlChiki: 'Which letter is "La"?',
                optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
                optionsLatin: ['a', 'at', 'ag', 'al'],
                correctIndex: 3,
              ),
            ],
          ),
        );
  }
}
