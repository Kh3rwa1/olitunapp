import 'package:flutter/material.dart';

class ScriptMetadata {
  final String scriptCode; // ISO 15924 (e.g., 'olck', 'wara', 'banc', 'tols')
  final String scriptName;
  final String nativeScriptName;
  final int unicodeRangeStart;
  final int unicodeRangeEnd;
  final TextDirection direction;
  final int consonantCount;
  final int vowelCount;
  final int modifierCount;

  const ScriptMetadata({
    required this.scriptCode,
    required this.scriptName,
    required this.nativeScriptName,
    required this.unicodeRangeStart,
    required this.unicodeRangeEnd,
    this.direction = TextDirection.ltr,
    required this.consonantCount,
    required this.vowelCount,
    required this.modifierCount,
  });

  int get totalGraphemes => consonantCount + vowelCount + modifierCount;

  bool containsRune(int rune) =>
      rune >= unicodeRangeStart && rune <= unicodeRangeEnd;
}
