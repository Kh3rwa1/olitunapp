import 'models/language_manifest.dart';
import 'models/script_metadata.dart';

class LanguageRegistry {
  const LanguageRegistry._();

  static const santali = LanguageManifest(
    code: 'sat',
    name: 'Santali',
    nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
    scriptCode: 'olck',
    scriptName: 'Ol Chiki',
    description:
        'Primary Austroasiatic language of the Santhal people across Jharkhand, Odisha, and West Bengal.',
    alphabetLetterCount: 30,
    sampleGlyphs: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱟ', 'ᱠ', 'ᱡ', 'ᱢ', 'ᱣ'],
    readiness: LanguageReadiness.active,
    audioPackSupported: true,
    offlineLessonsSupported: true,
    primaryFontFamily: 'OlChiki',
    fallbackFontFamilies: ['Inter'],
    scriptMetadata: ScriptMetadata(
      scriptCode: 'olck',
      scriptName: 'Ol Chiki',
      nativeScriptName: 'ᱚᱞ ᱪᱤᱠᱤ',
      unicodeRangeStart: 0x1C50,
      unicodeRangeEnd: 0x1C7F,
      consonantCount: 24,
      vowelCount: 6,
      modifierCount: 6,
    ),
  );

  static const ho = LanguageManifest(
    code: 'hoc',
    name: 'Ho',
    nativeName: '𑢹𑣉 ᱡᱟᱜᱟᱨ',
    scriptCode: 'wara',
    scriptName: 'Warang Citi',
    description:
        'Munda language spoken predominantly by the Ho people in Kolhan division and Mayurbhanj.',
    alphabetLetterCount: 32,
    sampleGlyphs: ['𑢹', '𑣉', '𑢡', '𑢲', '𑢳', '𑢴'],
    readiness: LanguageReadiness.preview,
    audioPackSupported: true,
    offlineLessonsSupported: false,
    primaryFontFamily: 'Inter',
    fallbackFontFamilies: ['OlChiki'],
    scriptMetadata: ScriptMetadata(
      scriptCode: 'wara',
      scriptName: 'Warang Citi',
      nativeScriptName: '𑢹𑣗𑢡𑣊 𑢔𑣂𑢻𑣂',
      unicodeRangeStart: 0x118A0,
      unicodeRangeEnd: 0x118FF,
      consonantCount: 26,
      vowelCount: 6,
      modifierCount: 2,
    ),
  );

  static const mundari = LanguageManifest(
    code: 'unr',
    name: 'Mundari',
    nativeName: 'ᱢᱩᱱᱰᱟᱹᱨᱤ ᱡᱟᱜᱟᱨ',
    scriptCode: 'banc',
    scriptName: 'Bani Ceti',
    description:
        'Major North Munda language spoken across the Chota Nagpur Plateau region.',
    alphabetLetterCount: 31,
    sampleGlyphs: ['ᱢ', 'ᱩ', 'ᱱ', 'ᱰ', 'ᱟ', 'ᱨ', 'ᱤ'],
    readiness: LanguageReadiness.preview,
    audioPackSupported: false,
    offlineLessonsSupported: false,
    primaryFontFamily: 'OlChiki',
    fallbackFontFamilies: ['Inter'],
    scriptMetadata: ScriptMetadata(
      scriptCode: 'banc',
      scriptName: 'Bani Ceti',
      nativeScriptName: 'ᱵᱟᱹᱱᱤ ᱪᱮᱛᱤ',
      unicodeRangeStart: 0x1C50,
      unicodeRangeEnd: 0x1C7F,
      consonantCount: 25,
      vowelCount: 6,
      modifierCount: 4,
    ),
  );

  static const kurukh = LanguageManifest(
    code: 'kru',
    name: 'Kurukh (Oraon)',
    nativeName: 'ᱠᱩᱲᱩᱠᱷ / कुड़ुख़',
    scriptCode: 'tols',
    scriptName: 'Tolong Siki',
    description:
        'Dravidian language spoken by the Kurukh/Oraon community in Jharkhand, Odisha, and Chhattisgarh.',
    alphabetLetterCount: 32,
    sampleGlyphs: ['ᱠ', 'ᱩ', 'ᱲ', 'ᱩ', 'ᱠ', 'ᱷ'],
    readiness: LanguageReadiness.comingSoon,
    audioPackSupported: false,
    offlineLessonsSupported: false,
    primaryFontFamily: 'Inter',
    fallbackFontFamilies: ['OlChiki'],
    scriptMetadata: ScriptMetadata(
      scriptCode: 'tols',
      scriptName: 'Tolong Siki',
      nativeScriptName: 'ᱛᱳᱞᱳᱝ ᱥᱤᱠᱤ',
      unicodeRangeStart: 0x1C50,
      unicodeRangeEnd: 0x1C7F,
      consonantCount: 26,
      vowelCount: 6,
      modifierCount: 3,
    ),
  );

  static const kui = LanguageManifest(
    code: 'kui',
    name: 'Kui (Kandha)',
    nativeName: 'ᱠᱩᱭᱤ / କୁଇ',
    scriptCode: 'kui',
    scriptName: 'Kui Script',
    description:
        'South-Eastern Dravidian language spoken by the Kandha tribe in the highlands of Odisha.',
    alphabetLetterCount: 28,
    sampleGlyphs: ['ᱠ', 'ᱩ', 'ᱭ', 'ᱤ'],
    readiness: LanguageReadiness.comingSoon,
    audioPackSupported: false,
    offlineLessonsSupported: false,
    primaryFontFamily: 'Inter',
    fallbackFontFamilies: ['OlChiki'],
    scriptMetadata: ScriptMetadata(
      scriptCode: 'kui',
      scriptName: 'Kui Script',
      nativeScriptName: 'ᱠᱩᱭᱤ',
      unicodeRangeStart: 0x1C50,
      unicodeRangeEnd: 0x1C7F,
      consonantCount: 22,
      vowelCount: 6,
      modifierCount: 2,
    ),
  );

  static const List<LanguageManifest> allLanguages = [
    santali,
    ho,
    mundari,
    kurukh,
    kui,
  ];

  static List<LanguageManifest> get activeLanguages => allLanguages
      .where((l) => l.readiness == LanguageReadiness.active)
      .toList();

  static List<LanguageManifest> get previewLanguages => allLanguages
      .where((l) => l.readiness == LanguageReadiness.preview)
      .toList();

  static List<LanguageManifest> get comingSoonLanguages => allLanguages
      .where((l) => l.readiness == LanguageReadiness.comingSoon)
      .toList();

  static LanguageManifest findByCode(String code) {
    return allLanguages.firstWhere(
      (l) => l.code.toLowerCase() == code.toLowerCase(),
      orElse: () => santali,
    );
  }
}
