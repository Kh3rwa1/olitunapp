import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/models/data_validation_result.dart';

void main() {
  group('DataValidationResult', () {
    test('ValidationSuccess carries its value', () {
      const result = ValidationSuccess<int>(7);
      expect(result.value, 7);
      expect(result, isA<DataValidationResult<int>>());
    });

    test('ValidationFailure carries id, reason and raw payload', () {
      const raw = {'title': 'broken'};
      const result = ValidationFailure<Map<String, dynamic>>(
        documentId: 'doc_1',
        reason: 'title must be a string',
        rawData: raw,
      );

      expect(result.documentId, 'doc_1');
      expect(result.reason, 'title must be a string');
      expect(result.rawData, raw);
    });

    test('ValidationFailure rawData is optional', () {
      const result = ValidationFailure<String>(
        documentId: 'doc_2',
        reason: 'missing field',
      );
      expect(result.rawData, isNull);
    });

    test('the two subtypes are distinguishable via pattern matching', () {
      const DataValidationResult<int> ok = ValidationSuccess<int>(1);
      const DataValidationResult<int> bad = ValidationFailure<int>(
        documentId: 'd',
        reason: 'r',
      );

      final outcomes = [ok, bad].map((r) {
        return switch (r) {
          ValidationSuccess<int>(:final value) => 'ok:$value',
          ValidationFailure<int>(:final documentId) => 'bad:$documentId',
        };
      }).toList();

      expect(outcomes, ['ok:1', 'bad:d']);
    });
  });
}
