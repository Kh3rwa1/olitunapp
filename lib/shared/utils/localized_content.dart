String primaryLocalizedText({
  required String olChiki,
  required String latin,
  required String scriptMode,
}) {
  final ol = olChiki.trim();
  final la = latin.trim();

  if (scriptMode == 'olchiki' && ol.isNotEmpty) return ol;
  if (scriptMode == 'latin' && la.isNotEmpty) return la;
  return la.isNotEmpty ? la : ol;
}

String? secondaryLocalizedText({
  required String olChiki,
  required String latin,
  required String scriptMode,
}) {
  final ol = olChiki.trim();
  final la = latin.trim();

  if (scriptMode == 'both') {
    if (ol.isEmpty || la.isEmpty) return null;
    return ol;
  }

  return null;
}

String? primaryLocalizedFontFamily(String scriptMode) {
  return scriptMode == 'olchiki' ? 'OlChiki' : null;
}
