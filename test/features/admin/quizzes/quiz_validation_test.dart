import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/quizzes/widgets/quiz_form_sheet/quiz_validation.dart';

void main() {
  group('QuizValidation.validateTitle', () {
    test('rejects a null title with a required message', () {
      expect(QuizValidation.validateTitle(null), 'Title is required');
    });

    test('rejects blank and whitespace-only titles', () {
      expect(QuizValidation.validateTitle(''), 'Title is required');
      expect(QuizValidation.validateTitle('   '), 'Title is required');
      expect(QuizValidation.validateTitle('\t\n'), 'Title is required');
    });

    test('accepts a non-empty title and trims surrounding whitespace', () {
      expect(QuizValidation.validateTitle('Alphabet Basics'), isNull);
      expect(QuizValidation.validateTitle('  padded title  '), isNull);
    });
  });

  group('QuizValidation.validateOrder', () {
    test('rejects a null order with a required message', () {
      expect(QuizValidation.validateOrder(null), 'Order is required');
    });

    test('rejects a blank order before attempting to parse', () {
      expect(QuizValidation.validateOrder(''), 'Order is required');
      expect(QuizValidation.validateOrder('   '), 'Order is required');
    });

    test('rejects non-integer text with an invalid-number message', () {
      expect(
        QuizValidation.validateOrder('first'),
        'Order must be a valid number',
      );
      expect(
        QuizValidation.validateOrder('1.5'),
        'Order must be a valid number',
      );
    });

    test('accepts any parseable integer including zero and negatives', () {
      expect(QuizValidation.validateOrder('0'), isNull);
      expect(QuizValidation.validateOrder('12'), isNull);
      expect(QuizValidation.validateOrder('-5'), isNull);
      expect(QuizValidation.validateOrder(' 12 '), isNull);
    });
  });

  group('QuizValidation.validatePassingScore', () {
    test('rejects a null passing score with a required message', () {
      expect(
        QuizValidation.validatePassingScore(null),
        'Passing score is required',
      );
    });

    test('rejects a blank passing score with a required message', () {
      expect(
        QuizValidation.validatePassingScore(''),
        'Passing score is required',
      );
      expect(
        QuizValidation.validatePassingScore('   '),
        'Passing score is required',
      );
    });

    test('rejects non-numeric text with the range message', () {
      expect(
        QuizValidation.validatePassingScore('eighty'),
        'Must be between 0 and 100',
      );
    });

    test('rejects scores below 0 and above 100', () {
      expect(
        QuizValidation.validatePassingScore('-1'),
        'Must be between 0 and 100',
      );
      expect(
        QuizValidation.validatePassingScore('101'),
        'Must be between 0 and 100',
      );
    });

    test('accepts the inclusive boundaries 0 and 100', () {
      expect(QuizValidation.validatePassingScore('0'), isNull);
      expect(QuizValidation.validatePassingScore('100'), isNull);
    });

    test('accepts a score surrounded by whitespace', () {
      expect(QuizValidation.validatePassingScore(' 50 '), isNull);
    });
  });
}
