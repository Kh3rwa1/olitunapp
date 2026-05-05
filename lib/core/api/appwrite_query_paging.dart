import 'dart:convert';

import 'package:appwrite/appwrite.dart';

class AppwriteQueryPaging {
  static const int defaultPageSize = 500;
  static const int maxPageSize = 500;

  const AppwriteQueryPaging._();

  static void validatePageSize(int pageSize) {
    if (pageSize < 1 || pageSize > maxPageSize) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'must be between 1 and $maxPageSize',
      );
    }
  }

  static List<String> queriesWithDefaultLimit(
    List<String>? queries,
    int pageSize,
  ) {
    final normalized = queries ?? const <String>[];
    if (normalized.any((query) => queryMethod(query) == 'limit')) {
      return normalized;
    }
    return [...normalized, Query.limit(pageSize)];
  }

  static List<String> withoutPaginationQueries(List<String>? queries) {
    return (queries ?? const <String>[])
        .where((query) {
          final method = queryMethod(query);
          return method != 'limit' && method != 'offset';
        })
        .toList(growable: false);
  }

  static bool containsManualPagination(List<String>? queries) {
    return (queries ?? const <String>[]).any((query) {
      final method = queryMethod(query);
      return method == 'offset' ||
          method == 'cursorBefore' ||
          method == 'cursorAfter' ||
          method == 'orderRandom';
    });
  }

  static List<String> pagedQueries(
    List<String> baseQueries, {
    required int limit,
    required int offset,
  }) {
    return [
      ...baseQueries,
      Query.limit(limit),
      if (offset > 0) Query.offset(offset),
    ];
  }

  static String? queryMethod(String query) {
    try {
      final parsed = jsonDecode(query);
      if (parsed is Map<String, dynamic>) {
        return parsed['method'] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
