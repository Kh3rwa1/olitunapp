import 'script_metadata.dart';

enum LanguageReadiness { active, preview, comingSoon }

class LanguageManifest {
  final String code; // ISO 639-3 (e.g. 'sat', 'hoc', 'unr', 'kui', 'kru')
  final String name; // English name (e.g. 'Santali')
  final String nativeName; // Native script name (e.g. 'ᱥᱟᱱᱛᱟᱲᱤ')
  final String scriptCode; // ISO 15924 ('olck', 'wara', etc.)
  final String scriptName;
  final String description;
  final int alphabetLetterCount;
  final List<String> sampleGlyphs;
  final LanguageReadiness readiness;
  final bool audioPackSupported;
  final bool offlineLessonsSupported;
  final String primaryFontFamily;
  final List<String> fallbackFontFamilies;
  final ScriptMetadata scriptMetadata;

  const LanguageManifest({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.scriptCode,
    required this.scriptName,
    required this.description,
    required this.alphabetLetterCount,
    required this.sampleGlyphs,
    required this.readiness,
    required this.audioPackSupported,
    required this.offlineLessonsSupported,
    required this.primaryFontFamily,
    required this.fallbackFontFamilies,
    required this.scriptMetadata,
  });

  bool get isFullySupported => readiness == LanguageReadiness.active;
}
