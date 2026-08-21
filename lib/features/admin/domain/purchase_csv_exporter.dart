import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/content_models.dart';

/// Status of an asynchronous or paginated purchase export operation.
enum PurchaseExportStatus { completed, truncated, cancelled, failed }

/// Typed result of an admin purchase export query.
@immutable
class PurchaseExportResult {
  final List<PurchaseModel> items;
  final int exportedCount;
  final int? totalEstimated;
  final bool isTruncated;
  final bool hasMore;
  final PurchaseExportStatus status;
  final String activeFilter;
  final String searchQuery;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? sanitizedFailure;

  const PurchaseExportResult({
    required this.items,
    required this.exportedCount,
    this.totalEstimated,
    required this.isTruncated,
    required this.hasMore,
    required this.status,
    required this.activeFilter,
    required this.searchQuery,
    required this.startedAt,
    required this.completedAt,
    this.sanitizedFailure,
  });

  bool get isSuccessful =>
      status == PurchaseExportStatus.completed ||
      status == PurchaseExportStatus.truncated;
}

/// Pure domain utility for generating RFC 4180 compliant CSVs from purchase records.
class PurchaseCsvExporter {
  PurchaseCsvExporter._();

  static const String schemaVersion = '1.0';
  static const String currency = 'INR';

  static const List<String> csvHeaders = [
    'Purchase ID',
    'Masked User ID',
    'Category ID',
    'Unlock Method',
    'Amount (INR)',
    'Razorpay Payment ID',
    'Razorpay Order ID',
    'Status',
    'Purchased At (UTC)',
    'Verified At (UTC)',
  ];

  /// Neutralizes spreadsheet formula injection (CSV Injection / CWE-1236).
  ///
  /// Prefixes cells starting with '=', '+', '-', '@', '\t', or '\r' with an apostrophe.
  static String sanitizeForCsv(String value) {
    if (value.isEmpty) return value;
    final firstChar = value[0];
    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r') {
      return "'$value";
    }
    return value;
  }

  /// Masks user identifiers to prevent PII exposure in exported reports.
  static String maskUserId(String userId) {
    if (userId.isEmpty) return '';
    if (userId.length <= 6) return 'u_****';
    return 'u_${userId.substring(0, 4)}***';
  }

  /// Escapes a single CSV cell according to RFC 4180 rules.
  static String escapeCsvCell(Object? value) {
    if (value == null) return '';
    final str = sanitizeForCsv(value.toString());

    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      final escaped = str.replaceAll('"', '""');
      return '"$escaped"';
    }
    return str;
  }

  /// Builds a complete UTF-8 CSV string with BOM, metadata comments, and sanitized rows.
  static String generateCsv({
    required List<PurchaseModel> items,
    required String exportScope,
    required String activeFilter,
    required String searchQuery,
    bool isTruncated = false,
    int? totalEstimatedCount,
    DateTime? timestampUtc,
  }) {
    final now = timestampUtc ?? DateTime.now().toUtc();
    final buffer = StringBuffer();

    // UTF-8 Byte Order Mark for Excel and Unicode compatibility (Santali / Ol Chiki)
    buffer.write('\uFEFF');

    // Structured metadata header comments
    buffer.writeln('# Olitun Admin Purchase Export');
    buffer.writeln('# Schema Version: $schemaVersion');
    buffer.writeln('# Generated (UTC): ${now.toIso8601String()}');
    buffer.writeln(
      '# Export Scope: $exportScope${isTruncated ? " (Truncated - Safety Limit Reached)" : " (Complete)"}',
    );
    buffer.writeln('# Filter: $activeFilter');
    buffer.writeln('# Search: ${searchQuery.isEmpty ? "none" : searchQuery}');
    buffer.writeln('# Currency: $currency');
    buffer.writeln('# Row Count: ${items.length}');
    if (totalEstimatedCount != null) {
      buffer.writeln('# Total Matching Records: $totalEstimatedCount');
    }
    buffer.writeln('# Complete: ${!isTruncated}');
    buffer.writeln('# PII Masking: Active (User IDs masked)');
    buffer.writeln('#');

    // CSV Column Headers
    buffer.writeln(csvHeaders.join(','));

    // Rows
    for (final p in items) {
      final row = <Object?>[
        p.id,
        maskUserId(p.userId),
        p.categoryId,
        p.unlockMethod,
        p.amountPaidInr,
        p.razorpayPaymentId ?? '',
        p.razorpayOrderId ?? '',
        p.status,
        p.purchasedAt,
        p.verifiedAt ?? '',
      ];

      buffer.writeln(row.map(escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  /// Returns UTF-8 encoded bytes for browser download or file writing.
  static Uint8List generateCsvBytes({
    required List<PurchaseModel> items,
    required String exportScope,
    required String activeFilter,
    required String searchQuery,
    bool isTruncated = false,
    int? totalEstimatedCount,
    DateTime? timestampUtc,
  }) {
    final csvString = generateCsv(
      items: items,
      exportScope: exportScope,
      activeFilter: activeFilter,
      searchQuery: searchQuery,
      isTruncated: isTruncated,
      totalEstimatedCount: totalEstimatedCount,
      timestampUtc: timestampUtc,
    );
    return Uint8List.fromList(utf8.encode(csvString));
  }
}
