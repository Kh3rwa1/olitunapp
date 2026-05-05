import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_query_paging.dart';

void main() {
  group('AppwriteDbService pagination queries', () {
    test('removes caller limit and offset before auto-pagination', () {
      final queries = [
        Query.orderAsc('order'),
        Query.limit(500),
        Query.offset(1000),
      ];

      final normalized = AppwriteQueryPaging.withoutPaginationQueries(queries);

      expect(normalized, hasLength(1));
      expect(AppwriteQueryPaging.queryMethod(normalized.single), 'orderAsc');
    });

    test('adds limit and offset for subsequent pages', () {
      final queries = AppwriteQueryPaging.pagedQueries(
        [Query.orderAsc('order')],
        limit: 250,
        offset: 500,
      );

      expect(queries.map(AppwriteQueryPaging.queryMethod), [
        'orderAsc',
        'limit',
        'offset',
      ]);
    });

    test('omits offset on the first page', () {
      final queries = AppwriteQueryPaging.pagedQueries(
        const [],
        limit: 500,
        offset: 0,
      );

      expect(queries.map(AppwriteQueryPaging.queryMethod), ['limit']);
    });

    test('detects manually paginated and random queries', () {
      expect(
        AppwriteQueryPaging.containsManualPagination([
          Query.cursorAfter('row-id'),
        ]),
        isTrue,
      );
      expect(
        AppwriteQueryPaging.containsManualPagination([Query.orderRandom()]),
        isTrue,
      );
      expect(
        AppwriteQueryPaging.containsManualPagination([
          Query.orderDesc(r'$updatedAt'),
          Query.limit(50),
        ]),
        isFalse,
      );
    });

    test('ignores malformed query strings when detecting methods', () {
      expect(AppwriteQueryPaging.queryMethod('not json'), isNull);
      expect(AppwriteQueryPaging.withoutPaginationQueries(['not json']), [
        'not json',
      ]);
    });

    test('rejects invalid page sizes', () {
      expect(
        () => AppwriteQueryPaging.validatePageSize(0),
        throwsArgumentError,
      );
      expect(
        () => AppwriteQueryPaging.validatePageSize(
          AppwriteQueryPaging.maxPageSize + 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
