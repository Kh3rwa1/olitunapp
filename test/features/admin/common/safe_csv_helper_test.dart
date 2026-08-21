import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/common/safe_csv_helper.dart';

void main() {
  group('SafeCsvHelper', () {
    test('neutralizes formula injection characters (=, +, -, @, tab, cr)', () {
      expect(SafeCsvHelper.escapeCell('=1+1'), "'=1+1");
      expect(SafeCsvHelper.escapeCell('+cmd|...'), "'+cmd|...");
      expect(SafeCsvHelper.escapeCell('-SUM(A1:A10)'), "'-SUM(A1:A10)");
      expect(SafeCsvHelper.escapeCell('@SUM(B1)'), "'@SUM(B1)");
      expect(SafeCsvHelper.escapeCell('\t=cmd'), "'\t=cmd");
      expect(SafeCsvHelper.escapeCell('\r=calc'), '"\'\r=calc"');
    });

    test('escapes quotes and handles commas and newlines', () {
      expect(SafeCsvHelper.escapeCell('Hello, World'), '"Hello, World"');
      expect(SafeCsvHelper.escapeCell('Hello "World"'), '"Hello ""World"""');
      expect(SafeCsvHelper.escapeCell('Line 1\nLine 2'), '"Line 1\nLine 2"');
    });

    test('preserves unicode and Ol Chiki script characters', () {
      const olChiki = 'ᱚᱞ ᱪᱤᱠᱤ';
      expect(SafeCsvHelper.escapeCell(olChiki), olChiki);
    });

    test('redacts secret credentials and api keys', () {
      expect(
        SafeCsvHelper.escapeCell('rzp_sec_abcdef1234567890'),
        '[REDACTED_SECRET]',
      );
      expect(
        SafeCsvHelper.escapeCell('secret_key_production_999'),
        '[REDACTED_SECRET]',
      );
    });

    test('builds complete CSV with metadata and headers', () {
      final headers = ['ID', 'Title', 'Price'];
      final rows = [
        ['1', 'Santali Primer', 199],
        ['2', '=1+1 Hack', 0],
        ['3', 'Ol Chiki "Advanced"', 299],
      ];
      final metadata = {
        'Export Date': '2026-08-21T12:00:00Z',
        'Scope': 'All Courses',
      };

      final csv = SafeCsvHelper.buildCsv(
        headers: headers,
        rows: rows,
        metadata: metadata,
      );

      expect(csv, contains('# Export Date,2026-08-21T12:00:00Z'));
      expect(csv, contains('# Scope,All Courses'));
      expect(csv, contains('ID,Title,Price'));
      expect(csv, contains('1,Santali Primer,199'));
      expect(csv, contains("2,'=1+1 Hack,0"));
      expect(csv, contains('3,"Ol Chiki ""Advanced""",299'));
    });
  });
}
