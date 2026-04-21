import 'package:equatable/equatable.dart';

class QuizResultEntity extends Equatable {
  final String quizId;
  final int score;
  final int totalQuestions;
  final String completedAt;

  const QuizResultEntity({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  bool get isPassing => totalQuestions > 0 && (score / totalQuestions) >= 0.7;

  @override
  List<Object?> get props => [quizId, score, totalQuestions, completedAt];
}
