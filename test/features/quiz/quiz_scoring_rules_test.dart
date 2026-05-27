import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/quiz_scoring_rules.dart';

void main() {
  group('QuizScoringRules Tests', () {
    test(
      'calculateStars calculates stars correctly with and without bonusStars',
      () {
        expect(QuizScoringRules.calculateStars(0), 0);
        expect(QuizScoringRules.calculateStars(3), 15);
        expect(QuizScoringRules.calculateStars(5, bonusStars: 2), 27);
        expect(QuizScoringRules.calculateStars(10, bonusStars: 5), 55);
      },
    );

    test('isPassing returns false for invalid parameters', () {
      expect(QuizScoringRules.isPassing(0, 0), isFalse);
      expect(QuizScoringRules.isPassing(5, -1), isFalse);
    });

    test(
      'isPassing returns correct passing/failing status based on 70% threshold',
      () {
        // 0/10 (0%) -> fail
        expect(QuizScoringRules.isPassing(0, 10), isFalse);
        // 6/10 (60%) -> fail
        expect(QuizScoringRules.isPassing(6, 10), isFalse);
        // 7/10 (70%) -> pass
        expect(QuizScoringRules.isPassing(7, 10), isTrue);
        // 8/10 (80%) -> pass
        expect(QuizScoringRules.isPassing(8, 10), isTrue);
        // 10/10 (100%) -> pass
        expect(QuizScoringRules.isPassing(10, 10), isTrue);

        // Boundary tests around 70%
        // 69/100 (69%) -> fail
        expect(QuizScoringRules.isPassing(69, 100), isFalse);
        // 70/100 (70%) -> pass
        expect(QuizScoringRules.isPassing(70, 100), isTrue);
      },
    );
  });
}
