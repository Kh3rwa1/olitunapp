import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/stale_while_revalidate_repository.dart';

void main() {
  group('SWRResult Data Model Tests', () {
    test('hasData returns true when data is present', () {
      const result = SWRResult<String>(
        data: 'cached_item',
        state: SWRState.cached,
      );
      expect(result.hasData, isTrue);
      expect(result.data, 'cached_item');
      expect(result.isStale, isFalse);
    });

    test('isStale flag is preserved correctly', () {
      const result = SWRResult<String>(
        data: 'stale_item',
        state: SWRState.stale,
        isStale: true,
      );
      expect(result.hasData, isTrue);
      expect(result.isStale, isTrue);
    });

    test('errorWithCache retains data and sets error message', () {
      const result = SWRResult<String>(
        data: 'last_known_good',
        state: SWRState.errorWithCache,
        error: 'Network failure',
        isStale: true,
      );
      expect(result.hasData, isTrue);
      expect(result.error, 'Network failure');
      expect(result.state, SWRState.errorWithCache);
    });
  });
}
