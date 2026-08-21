import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/shared/models/content_models.dart';

PurchaseModel makeTestPurchaseItem({
  required String id,
  required String userId,
  required String categoryId,
  required String unlockMethod,
  required int amountPaidInr,
  required String status,
  String? paymentId,
  String purchasedAt = '2026-08-21T10:00:00Z',
}) {
  return PurchaseModel(
    id: id,
    userId: userId,
    categoryId: categoryId,
    unlockMethod: unlockMethod,
    amountPaidInr: amountPaidInr,
    status: status,
    razorpayPaymentId: paymentId,
    purchasedAt: purchasedAt,
  );
}

void main() {
  group('PurchaseCsvExporter - Complete Export & Safety Limit Matrix', () {
    test(
      'Case 1: neutralizes formula injection starting with =, +, -, @, tab, cr',
      () {
        expect(PurchaseCsvExporter.sanitizeForCsv('=1+1'), "'=1+1");
        expect(PurchaseCsvExporter.sanitizeForCsv('+cmd|calc'), "'+cmd|calc");
        expect(PurchaseCsvExporter.sanitizeForCsv('-20'), "'-20");
        expect(PurchaseCsvExporter.sanitizeForCsv('@export'), "'@export");
        expect(PurchaseCsvExporter.sanitizeForCsv('\tcmd'), "'\tcmd");
        expect(PurchaseCsvExporter.sanitizeForCsv('\rcmd'), "'\rcmd");
        expect(
          PurchaseCsvExporter.sanitizeForCsv('normal_value'),
          'normal_value',
        );
      },
    );

    test('Case 2: masks user identifiers correctly', () {
      expect(PurchaseCsvExporter.maskUserId('usr_abc123456'), 'u_usr_***');
      expect(PurchaseCsvExporter.maskUserId('short'), 'u_****');
      expect(PurchaseCsvExporter.maskUserId(''), '');
    });

    test(
      'Case 3: properly escapes cells containing commas, quotes, and newlines',
      () {
        expect(
          PurchaseCsvExporter.escapeCsvCell('Hello, World'),
          '"Hello, World"',
        );
        expect(
          PurchaseCsvExporter.escapeCsvCell('Quote "test"'),
          '"Quote ""test"""',
        );
        expect(
          PurchaseCsvExporter.escapeCsvCell('Line1\nLine2'),
          '"Line1\nLine2"',
        );
        expect(PurchaseCsvExporter.escapeCsvCell(299), '299');
      },
    );

    test('Case 4: preserves Santali / Ol Chiki characters with UTF-8 BOM', () {
      final purchases = [
        makeTestPurchaseItem(
          id: 'doc_1',
          userId: 'usr_santali_1',
          categoryId: 'santali_sentences_ᱟ_ᱵ',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
        ),
      ];

      final csv = PurchaseCsvExporter.generateCsv(
        items: purchases,
        exportScope: 'All Matching Results',
        activeFilter: 'all',
        searchQuery: '',
      );

      expect(csv.startsWith('\uFEFF'), isTrue); // UTF-8 BOM
      expect(csv, contains('santali_sentences_ᱟ_ᱵ'));
      expect(csv, contains('# Complete: true'));
      expect(csv, contains('# Schema Version: 1.0'));
    });

    test('Case 5: generates accurate metadata manifest for 0 records', () {
      final csv = PurchaseCsvExporter.generateCsv(
        items: [],
        exportScope: 'All Matching Results',
        activeFilter: 'all',
        searchQuery: '',
      );

      expect(csv, contains('# Row Count: 0'));
      expect(csv, contains('# Complete: true'));
      expect(csv, contains('Purchase ID,Masked User ID,Category ID'));
    });

    test('Case 6: handles 1, 49, 50, 51 records with complete metadata', () {
      for (final count in [1, 49, 50, 51]) {
        final items = List.generate(
          count,
          (i) => makeTestPurchaseItem(
            id: 'p_$i',
            userId: 'user_$i',
            categoryId: 'basics',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
          ),
        );

        final csv = PurchaseCsvExporter.generateCsv(
          items: items,
          exportScope: 'All Matching Results',
          activeFilter: 'razorpay',
          searchQuery: '',
        );

        expect(csv, contains('# Row Count: $count'));
        expect(csv, contains('# Complete: true'));
      }
    });

    test('Case 7: handles 5000 records without truncation flag', () {
      final items = List.generate(
        5000,
        (i) => makeTestPurchaseItem(
          id: 'p_$i',
          userId: 'user_$i',
          categoryId: 'basics',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
        ),
      );

      final csv = PurchaseCsvExporter.generateCsv(
        items: items,
        exportScope: 'All Matching Results',
        activeFilter: 'all',
        searchQuery: '',
      );

      expect(csv, contains('# Row Count: 5000'));
      expect(csv, contains('# Complete: true'));
      expect(csv.contains('Truncated'), isFalse);
    });

    test('Case 8: explicitly labels truncated exports at safety threshold', () {
      final items = List.generate(
        5001,
        (i) => makeTestPurchaseItem(
          id: 'p_$i',
          userId: 'user_$i',
          categoryId: 'basics',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
        ),
      );

      final csv = PurchaseCsvExporter.generateCsv(
        items: items,
        exportScope: 'All Matching Results',
        activeFilter: 'all',
        searchQuery: '',
        isTruncated: true,
      );

      expect(csv, contains('# Row Count: 5001'));
      expect(
        csv,
        contains(
          '# Export Scope: All Matching Results (Truncated - Safety Limit Reached)',
        ),
      );
      expect(csv, contains('# Complete: false'));
    });

    test('Case 9: generateCsvBytes produces valid UTF-8 byte stream', () {
      final items = [
        makeTestPurchaseItem(
          id: 'p_byte',
          userId: 'u_byte_123',
          categoryId: 'santali_words',
          unlockMethod: 'razorpay',
          amountPaidInr: 499,
          status: 'verified',
        ),
      ];

      final bytes = PurchaseCsvExporter.generateCsvBytes(
        items: items,
        exportScope: 'Visible Rows',
        activeFilter: 'all',
        searchQuery: '',
      );

      final decoded = utf8.decode(bytes);
      expect(decoded, contains('# Olitun Admin Purchase Export'));
      expect(decoded, contains('santali_words'));
      expect(decoded, contains('u_u_by***'));
    });
  });
}
