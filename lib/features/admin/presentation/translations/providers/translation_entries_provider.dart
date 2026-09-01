import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/providers/providers.dart';
import '../models/translation_entry.dart';

final translationEntriesProvider = Provider<List<TranslationEntry>>((ref) {
  final entries = <TranslationEntry>[];

  // 1. Words
  final wordsAsync = ref.watch(wordsProvider);
  wordsAsync.whenData((words) {
    for (final w in words) {
      entries.add(
        TranslationEntry(
          id: w.id,
          kind: TranslationKind.word,
          textOlChiki: w.wordOlChiki,
          textLatin: w.wordLatin,
          englishMeaning: w.meaning,
          pronunciation: w.pronunciation,
          category: w.category,
          audioUrl: w.audioUrl,
        ),
      );
    }
  });

  // 2. Sentences
  final sentencesAsync = ref.watch(sentencesProvider);
  sentencesAsync.whenData((sentences) {
    for (final s in sentences) {
      entries.add(
        TranslationEntry(
          id: s.id,
          kind: TranslationKind.sentence,
          textOlChiki: s.sentenceOlChiki,
          textLatin: s.sentenceLatin,
          englishMeaning: s.meaning,
          pronunciation: s.pronunciation,
          category: s.category,
          audioUrl: s.audioUrl,
        ),
      );
    }
  });

  // 3. Lessons and Lesson Blocks
  final lessonsAsync = ref.watch(lessonNotifierProvider);
  lessonsAsync.whenData((lessons) {
    for (final l in lessons) {
      entries.add(
        TranslationEntry(
          id: l.id,
          kind: TranslationKind.lesson,
          textOlChiki: l.titleOlChiki,
          textLatin: l.titleLatin,
          englishMeaning:
              (l.description != null && l.description!.isNotEmpty)
                  ? l.description!
                  : l.titleLatin,
          category: l.categoryId,
        ),
      );
      for (var i = 0; i < l.blocks.length; i++) {
        final b = l.blocks[i];
        if ((b.textOlChiki != null && b.textOlChiki!.isNotEmpty) ||
            (b.textLatin != null && b.textLatin!.isNotEmpty)) {
          final dataMeaning = b.data?['meaning'] as String?;
          final dataTrans = b.data?['translation'] as String?;
          entries.add(
            TranslationEntry(
              id: '${l.id}_block_$i',
              kind: TranslationKind.lesson,
              textOlChiki: b.textOlChiki ?? '',
              textLatin: b.textLatin ?? '',
              englishMeaning: dataMeaning ?? dataTrans ?? b.textLatin ?? '',
              pronunciation: b.data?['pronunciation'] as String?,
              category: l.titleLatin,
              audioUrl: b.audioUrl,
            ),
          );
        }
      }
    }
  });

  // 4. Categories
  final categoriesAsync = ref.watch(categoryNotifierProvider);
  categoriesAsync.whenData((categories) {
    for (final c in categories) {
      entries.add(
        TranslationEntry(
          id: c.id,
          kind: TranslationKind.category,
          textOlChiki: c.titleOlChiki,
          textLatin: c.titleLatin,
          englishMeaning: c.description ?? c.titleLatin,
          category: 'Category',
        ),
      );
    }
  });

  // 5. Rhymes & Stories
  final rhymesAsync = ref.watch(rhymesProvider);
  rhymesAsync.whenData((rhymes) {
    for (final r in rhymes) {
      entries.add(
        TranslationEntry(
          id: r.id,
          kind: TranslationKind.rhyme,
          textOlChiki: r.titleOlChiki,
          textLatin: r.titleLatin,
          englishMeaning: r.contentLatin.isNotEmpty ? r.contentLatin : r.titleLatin,
          category: r.category ?? r.categoryId,
          audioUrl: r.audioUrl,
        ),
      );
    }
  });

  return entries;
});
