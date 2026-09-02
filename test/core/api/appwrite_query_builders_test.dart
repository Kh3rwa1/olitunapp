import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_query_builders.dart';

void main() {
  group('DbQuery', () {
    test('equal builds an equal query string', () {
      final q = DbQuery.equal('userId', 'u_1');
      expect(q, contains('"method":"equal"'));
      expect(q, contains('"attribute":"userId"'));
      expect(q, contains('"values":["u_1"]'));
    });

    test('notEqual builds a notEqual query string', () {
      final q = DbQuery.notEqual('status', 'deleted');
      expect(q, contains('"method":"notEqual"'));
      expect(q, contains('"attribute":"status"'));
    });

    test('comparison builders carry their method name', () {
      expect(
        DbQuery.greaterThan('order', 3),
        contains('"method":"greaterThan"'),
      );
      expect(
        DbQuery.greaterThanEqual('dateKey', '2026-01-01'),
        contains('"method":"greaterThanEqual"'),
      );
      expect(DbQuery.lessThan('order', 9), contains('"method":"lessThan"'));
      expect(
        DbQuery.lessThanEqual('dateKey', '2026-12-31'),
        contains('"method":"lessThanEqual"'),
      );
    });

    test('limit caps results', () {
      expect(DbQuery.limit(25), contains('"method":"limit"'));
      expect(DbQuery.limit(25), contains('"values":[25]'));
    });

    test('order builders carry direction', () {
      expect(DbQuery.orderAsc('order'), contains('"method":"orderAsc"'));
      expect(DbQuery.orderDesc('order'), contains('"method":"orderDesc"'));
    });

    test('search targets an attribute', () {
      final q = DbQuery.search('title', 'letters');
      expect(q, contains('"method":"search"'));
      expect(q, contains('"attribute":"title"'));
    });

    test('queries are plain JSON strings usable by the db service', () {
      final q = DbQuery.equal('kind', 'word');
      expect(q, isA<String>());
      expect(q.startsWith('{'), isTrue);
    });
  });

  group('DbId', () {
    test('unique produces non-empty ids', () {
      expect(DbId.unique(), isNotEmpty);
    });

    test('unique produces distinct ids', () {
      final ids = {DbId.unique(), DbId.unique(), DbId.unique()};
      expect(ids, hasLength(3));
    });
  });
}
