import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/languages/language_registry.dart';

void main() {
  group('LanguageRegistry Multi-Language Platform Tests', () {
    test('contains all 5 canonical indigenous languages', () {
      expect(LanguageRegistry.allLanguages.length, equals(5));

      final codes = LanguageRegistry.allLanguages.map((l) => l.code).toSet();
      expect(codes, containsAll({'sat', 'hoc', 'unr', 'kru', 'kui'}));
    });

    test(
      'correctly categorizes active, preview, and coming soon languages',
      () {
        final active = LanguageRegistry.activeLanguages;
        final preview = LanguageRegistry.previewLanguages;
        final comingSoon = LanguageRegistry.comingSoonLanguages;

        expect(active.map((l) => l.code), contains('sat'));
        expect(preview.map((l) => l.code), containsAll({'hoc', 'unr'}));
        expect(comingSoon.map((l) => l.code), containsAll({'kru', 'kui'}));
      },
    );

    test('findByCode returns matching manifest or default fallback', () {
      final ho = LanguageRegistry.findByCode('hoc');
      expect(ho.name, equals('Ho'));
      expect(ho.scriptCode, equals('wara'));

      final fallback = LanguageRegistry.findByCode('unknown_lang');
      expect(fallback.code, equals('sat'));
    });
  });
}
