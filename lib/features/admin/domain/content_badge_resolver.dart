import '../../../../shared/models/content_item.dart';

enum ContentBadgeType {
  letters,
  numbers,
  words,
  sentences,
  video,
  audio,
  quiz,
  tracing,
  typing,
  lesson; // Generic fallback only
}

/// A pure domain resolver to map ContentKind and parent category/block contexts
/// to a unified, highly descriptive ContentBadgeType.
ContentBadgeType resolveBadgeType({
  required ContentKind kind,
  String? categoryId,
  String? categorySlug,
  String? blockType,
}) {
  // 1. If it is a block inside the Lesson Editor, blockType takes precedence
  if (blockType != null) {
    switch (blockType) {
      case 'audio':
        return ContentBadgeType.audio;
      case 'video':
        return ContentBadgeType.video;
      case 'quiz':
        return ContentBadgeType.quiz;
      case 'tracing':
        return ContentBadgeType.tracing;
      // Presentation blocks (text, image, svg, lottie, glyph, callout)
      // fallback to the parent lesson's badge type
      default:
        break;
    }
  }

  // 2. Resolve content category mapping (case-insensitive and whitespace tolerant)
  final normalizedSlug = (categorySlug ?? '').toLowerCase().trim();
  final normalizedId = (categoryId ?? '').toLowerCase().trim();

  final isLettersCat = normalizedId == 'cat_alphabets' ||
      normalizedSlug.contains('alphabet') ||
      normalizedSlug.contains('letter');

  final isNumbersCat = normalizedId == 'cat_numbers' ||
      normalizedSlug.contains('number');

  final isWordsCat = normalizedId == 'cat_vocabulary' ||
      normalizedSlug.contains('vocab') ||
      normalizedSlug.contains('word');

  final isSentencesCat = normalizedId == 'cat_sentences' ||
      normalizedId == 'cat_greetings' ||
      normalizedSlug.contains('sentence') ||
      normalizedSlug.contains('greeting');

  // 3. Map based on ContentKind
  switch (kind) {
    case ContentKind.letter:
      return ContentBadgeType.letters;
    case ContentKind.number:
      return ContentBadgeType.numbers;
    case ContentKind.word:
      return ContentBadgeType.words;
    case ContentKind.sentence:
      return ContentBadgeType.sentences;
    case ContentKind.rhyme:
      // TODO: If ContentBadgeType.rhyme is ever needed as a distinct visual,
      // map it here. For now, rhymes are audio play-along, so they map to audio.
      return ContentBadgeType.audio;
    case ContentKind.lesson:
      if (isLettersCat || isNumbersCat) {
        return ContentBadgeType.tracing; // Lessons on letters/numbers are tracing exercises
      }
      if (isWordsCat || isSentencesCat) {
        return ContentBadgeType.typing; // Lessons on words/sentences are typing exercises
      }
      return ContentBadgeType.lesson; // Generic fallback
  }
}
