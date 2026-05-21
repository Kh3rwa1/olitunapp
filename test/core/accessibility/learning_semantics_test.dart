import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/learning_semantics.dart';

void main() {
  group('LearningSemantics', () {
    test('builds descriptive Ol Chiki text labels', () {
      expect(
        LearningSemantics.olChikiText(
          text: 'ᱚ',
          latin: 'a',
          meaning: 'first vowel',
        ),
        'Ol Chiki text ᱚ, Latin reading a, Meaning first vowel',
      );
    });

    test('builds quiz question labels without empty optional parts', () {
      expect(
        LearningSemantics.quizQuestion(prompt: 'ᱚ'),
        'Quiz question, Ol Chiki prompt ᱚ',
      );
    });

    test('builds answer state labels', () {
      expect(
        LearningSemantics.quizOption(
          index: 1,
          option: 'e',
          isSelected: true,
          isAnswered: true,
        ),
        'Answer B, e, selected, incorrect',
      );
    });
  });
}
