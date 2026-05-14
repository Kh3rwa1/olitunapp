import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/providers/quizzes_provider.dart';

class QuizRepository {
  final Ref _ref;

  QuizRepository(this._ref);

  Future<QuizModel?> getQuiz(String quizId) async {
    final quizzesAsync = _ref.read(quizzesProvider);
    final quizzes = quizzesAsync.value ?? [];
    try {
      return quizzes.firstWhere((q) => q.id == quizId);
    } catch (_) {
      return null;
    }
  }
}

final quizRepositoryProvider = Provider(QuizRepository.new);

final quizFutureProvider = FutureProvider.family<QuizModel?, String>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuiz(quizId);
});
