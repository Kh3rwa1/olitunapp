import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/languages/models/language_manifest.dart';
import 'package:itun/core/languages/models/script_metadata.dart';

void main() {
  group('LanguageManifest & ScriptMetadata Model Tests', () {
    const testScript = ScriptMetadata(
      scriptCode: 'olck',
      scriptName: 'Ol Chiki',
      nativeScriptName: 'ᱚᱞ ᱪᱤᱠᱤ',
      unicodeRangeStart: 0x1C50,
      unicodeRangeEnd: 0x1C7F,
      consonantCount: 24,
      vowelCount: 6,
      modifierCount: 6,
    );

    const manifest = LanguageManifest(
      code: 'sat',
      name: 'Santali',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
      scriptCode: 'olck',
      scriptName: 'Ol Chiki',
      description: 'Primary Austroasiatic language of the Santhal people.',
      alphabetLetterCount: 30,
      sampleGlyphs: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
      readiness: LanguageReadiness.active,
      audioPackSupported: true,
      offlineLessonsSupported: true,
      primaryFontFamily: 'OlChiki',
      fallbackFontFamilies: ['Inter'],
      scriptMetadata: testScript,
    );

    test('validates script metadata graphemes and unicode range checking', () {
      expect(testScript.totalGraphemes, equals(36));
      expect(testScript.containsRune(0x1C50), isTrue); // 'ᱚ'
      expect(testScript.containsRune(0x1C7F), isTrue);
      expect(testScript.containsRune(0x0041), isFalse); // 'A'
    });

    test(
      'validates language manifest properties and active readiness state',
      () {
        expect(manifest.code, equals('sat'));
        expect(manifest.isFullySupported, isTrue);
        expect(manifest.audioPackSupported, isTrue);
        expect(manifest.offlineLessonsSupported, isTrue);
        expect(manifest.primaryFontFamily, equals('OlChiki'));
      },
    );
  });
}
