bool isTextMatch(String blockText, String entityText, {bool isLetter = false}) {
  if (entityText.isEmpty) return false;
  final t = blockText.trim().toLowerCase();
  final e = entityText.trim().toLowerCase();

  // Exact match
  if (t == e) return true;

  // Clean punctuation
  final tClean = t.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  final eClean = e.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();

  if (tClean == eClean && tClean.isNotEmpty) return true;

  // For letters, we allow substring matching because a word block contains multiple letters.
  if (isLetter) {
    if (t.contains(e) || tClean.contains(eClean)) return true;
    return false;
  }

  // For words/sentences, check if the entity is a standalone token in the block text
  final tokens = t.split(RegExp(r'[\s\-\–\—\−\.\!\?\:\;]+'));
  if (tokens.any((token) => token == e || token == eClean)) return true;

  return false;
}
