import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/practice/domain/practice_scoring_rules.dart';

void main() {
  group('PracticeScoringRules', () {
    test('starsPerTypingCompletion is exactly 5', () {
      expect(PracticeScoringRules.starsPerTypingCompletion, equals(5));
    });
  });
}
