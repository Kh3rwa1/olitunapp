import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_service.dart';
import '../models/content_models.dart';

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>(
      (ref) => QuizzesNotifier(),
    );

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier() : super(const AsyncValue.loading()) {
    _loadQuizzes();
  }

  void _loadQuizzes() {
    try {
      final stored = prefs.getString('quizzes');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        state = AsyncValue.data(
          decoded.map((e) => QuizModel.fromJson(e)).toList(),
        );
      } else {
        final defaultQuizzes = [
          QuizModel(
            id: 'quiz_alphabets_basics', categoryId: 'alphabets',
            title: 'Alphabet Basics', level: 'beginner', order: 0,
            isActive: true, passingScore: 70,
            questions: [
              QuizQuestion(
                promptOlChiki: 'ᱚ', promptLatin: 'Which sound does this letter make?',
                optionsOlChiki: ['a', 'i', 'u', 'o'],
                optionsLatin: ['a', 'i', 'u', 'o'], correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱛ', promptLatin: 'Identify this consonant:',
                optionsOlChiki: ['at', 'ag', 'al', 'ak'],
                optionsLatin: ['at', 'ag', 'al', 'ak'], correctIndex: 0,
              ),
            ],
          ),
          QuizModel(
            id: 'quiz_numbers_1to10', categoryId: 'numbers',
            title: 'Numbers 1-10', level: 'beginner', order: 1,
            isActive: true, passingScore: 70,
            questions: [
              QuizQuestion(
                promptOlChiki: '᱑', promptLatin: 'What number is this?',
                optionsOlChiki: ['1', '2', '3', '4'],
                optionsLatin: ['One', 'Two', 'Three', 'Four'], correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: '᱕', promptLatin: 'Identify this number:',
                optionsOlChiki: ['3', '4', '5', '6'],
                optionsLatin: ['Three', 'Four', 'Five', 'Six'], correctIndex: 2,
              ),
            ],
          ),
          QuizModel(
            id: 'quiz_vowels', categoryId: 'alphabets',
            title: 'Master the Vowels', level: 'intermediate', order: 2,
            isActive: true, passingScore: 80,
            questions: [
              QuizQuestion(
                promptOlChiki: 'ᱤ', promptLatin: 'This is the vowel for:',
                optionsOlChiki: ['a', 'i', 'u', 'e'],
                optionsLatin: ['a', 'i', 'u', 'e'], correctIndex: 1,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱩ', promptLatin: 'Identify this vowel sound:',
                optionsOlChiki: ['a', 'i', 'u', 'o'],
                optionsLatin: ['a', 'i', 'u', 'o'], correctIndex: 2,
              ),
            ],
          ),
        ];
        state = AsyncValue.data(defaultQuizzes);
        _saveQuizzes(defaultQuizzes);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  void _saveQuizzes(List<QuizModel> quizzes) {
    final encoded = jsonEncode(quizzes.map((e) => e.toJson()).toList());
    prefs.setString('quizzes', encoded);
  }

  void add(QuizModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  void update(QuizModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addQuiz(QuizModel item) async => add(item);
  Future<void> updateQuiz(QuizModel item) async => update(item);
  Future<void> deleteQuiz(String id) async => delete(id);

  Future<void> seed() async {
    state = const AsyncValue.loading();
    prefs.remove('quizzes');
    _loadQuizzes();
  }
}
