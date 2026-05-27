import 'package:equatable/equatable.dart';
import '../../../quiz/domain/quiz_scoring_rules.dart';

class QuizResultEntity extends Equatable {
  final String quizId;
  final int score;
  final int totalQuestions;
  final String completedAt;
  final bool? failedNoHearts;

  const QuizResultEntity({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    this.failedNoHearts,
  });

  bool get isPassing =>
      failedNoHearts != true &&
      QuizScoringRules.isPassing(score, totalQuestions);

  @override
  List<Object?> get props => [
    quizId,
    score,
    totalQuestions,
    completedAt,
    failedNoHearts,
  ];
}
