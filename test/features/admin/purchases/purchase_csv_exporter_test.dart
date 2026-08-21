import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('PurchaseCsvExporter', () {
    final samplePurchases = [
      PurchaseModel(
        id: 'doc_1',
        userId: 'usr_abc123456',
        categoryId: 'santali_basics_ol_chiki',
        unlockMethod: 'razorpay',
        amountPaidInr: 299,
        razorpayPaymentId: 'pay_12345678',
        razorpayOrderId: 'order_12345678',
        status: 'verified',
        purchasedAt: '2026-08-21T10:00:00Z',
        verifiedAt: '2026-08-21T10:00:05Z',
      ),
      PurchaseModel(
        id: 'doc_2',
        userId: 'usr_short',
        categoryId: 'santali_sentences_ᱟ_ᱵ',
        unlockMethod: 'play_store_review',
        amountPaidInr: 0,
        status: 'verified',
        purchasedAt: '2026-08-21T11:00:00Z',
      ),
      PurchaseModel(
        id: 'doc_3',
        userId: 'usr_injected',
        categoryId: '=1+1',
        unlockMethod: 'razorpay',
        amountPaidInr: 199,
        razorpayPaymentId: '@malicious_pay',
        status: 'refunded',
        purchasedAt: '2026-08-21T12:00:00Z',
      ),
    ];

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

    test(
      'Case 4: preserves Santali / Ol Chiki characters in generated CSV',
      () {
        final csv = PurchaseCsvExporter.generateCsv(
          items: samplePurchases,
          exportScope: 'All Matching Results',
          activeFilter: 'all',
          searchQuery: '',
        );

        expect(csv, contains('santali_sentences_ᱟ_ᱵ'));
        expect(csv.startsWith('\uFEFF'), isTrue); // Starts with UTF-8 BOM
      },
    );

    test('Case 5: encodes CSV bytes into valid UTF-8', () {
      final bytes = PurchaseCsvExporter.generateCsvBytes(
        items: samplePurchases,
        exportScope: 'Visible Rows',
        activeFilter: 'razorpay',
        searchQuery: 'santali',
      );

      final decoded = utf8.decode(bytes);
      expect(decoded, contains('# Olitun Admin Purchase Export'));
      expect(decoded, contains('santali_basics_ol_chiki'));
      expect(decoded, contains("'=1+1"));
      expect(decoded, contains("'@malicious_pay"));
    });
  });
}
