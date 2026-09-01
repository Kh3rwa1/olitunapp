import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/script_typography_registry.dart';

void main() {
  group('ScriptTypographyRegistry Tests', () {
    test('resolves correct primary font family and fallbacks for Santali', () {
      final family = ScriptTypographyRegistry.getFontFamily('sat');
      final fallbacks = ScriptTypographyRegistry.getFontFallbacks('sat');

      expect(family, equals('OlChiki'));
      expect(fallbacks, contains('Inter'));
    });

    test(
      'resolves correct font style for Ol Chiki vs Latin/Inter languages',
      () {
        final olChikiStyle = ScriptTypographyRegistry.getStyle(
          languageCode: 'sat',
        );
        expect(olChikiStyle.fontFamily, equals('OlChiki'));

        final interStyle = ScriptTypographyRegistry.getStyle(
          languageCode: 'hoc',
        );
        expect(interStyle.fontFamily, equals('Inter'));
      },
    );
  });
}
