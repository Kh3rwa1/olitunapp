import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/quizzes_provider.dart';

class QuizRepository {
  final Ref _ref;

  QuizRepository(this._ref);

  Future<QuizModel> getQuiz(String quizId) async {
    final quizzesAsync = _ref.read(quizzesProvider);
    final quizzes = quizzesAsync.value ?? [];
    return quizzes.firstWhere((q) => q.id == quizId);
  }
}

final quizRepositoryProvider = Provider(QuizRepository.new);
