import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/content_models.dart';

/// Pure domain utility for generating audit-compliant, injection-safe CSV exports.
class PurchaseCsvExporter {
  const PurchaseCsvExporter._();

  /// Column headers for purchase exports in deterministic order.
  static const List<String> headers = [
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

  /// Neutralizes CSV / Spreadsheet formula injection vulnerabilities.
  ///
  /// Prepends a single quote if the field begins with '=', '+', '-', '@', '\t', or '\r'.
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

  /// Masks user identifiers to prevent unnecessary PII leakage in exports.
  static String maskUserId(String userId) {
    final clean = userId.trim();
    if (clean.isEmpty) return '';
    if (clean.length <= 6) return 'u_****';
    return 'u_${clean.substring(0, 4)}***';
  }

  /// Encodes a single cell into standard RFC 4180 CSV syntax.
  static String escapeCsvCell(Object? value) {
    if (value == null) return '';
    String str;
    if (value is num || value is bool) {
      str = value.toString();
    } else {
      str = sanitizeForCsv(value.toString());
    }

    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Generates complete CSV content as a UTF-8 string with optional metadata manifest.
  static String generateCsv({
    required List<PurchaseModel> items,
    required String exportScope,
    required String activeFilter,
    required String searchQuery,
    String currency = 'INR',
    DateTime? timestampUtc,
  }) {
    final now = (timestampUtc ?? DateTime.now().toUtc()).toIso8601String();
    final buffer = StringBuffer();

    // UTF-8 Byte Order Mark (BOM) for seamless Excel & spreadsheet Unicode rendering
    buffer.write('\uFEFF');

    // Structured metadata header comments
    buffer.writeln('# Olitun Admin Purchase Export');
    buffer.writeln('# Generated (UTC): $now');
    buffer.writeln('# Export Scope: $exportScope (${items.length} rows)');
    buffer.writeln(
      '# Filter: $activeFilter | Search: ${searchQuery.isEmpty ? "none" : searchQuery}',
    );
    buffer.writeln('# Currency: $currency | PII Masking: Active');
    buffer.writeln('# Schema Version: 1.0');

    // CSV Header row
    buffer.writeln(headers.map(escapeCsvCell).join(','));

    // Data rows
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

  /// Returns UTF-8 encoded bytes with BOM.
  static Uint8List generateCsvBytes({
    required List<PurchaseModel> items,
    required String exportScope,
    required String activeFilter,
    required String searchQuery,
    String currency = 'INR',
    DateTime? timestampUtc,
  }) {
    final csvString = generateCsv(
      items: items,
      exportScope: exportScope,
      activeFilter: activeFilter,
      searchQuery: searchQuery,
      currency: currency,
      timestampUtc: timestampUtc,
    );
    return Uint8List.fromList(utf8.encode(csvString));
  }
}
