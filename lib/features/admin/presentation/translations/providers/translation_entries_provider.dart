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
      final lCustomTranslations = <String, String>{};
      if (l.data != null) {
        for (final k in ['bn', 'hi', 'or', 'en']) {
          final val = l.data!['meaning_$k'] as String?;
          if (val != null && val.trim().isNotEmpty) {
            lCustomTranslations[k] = val.trim();
          }
        }
      }

      entries.add(
        TranslationEntry(
          id: l.id,
          kind: TranslationKind.lesson,
          textOlChiki: l.titleOlChiki,
          textLatin: l.titleLatin,
          englishMeaning: (l.description != null && l.description!.isNotEmpty)
              ? l.description!
              : l.titleLatin,
          category: l.categoryId,
          customTranslations: lCustomTranslations.isNotEmpty
              ? lCustomTranslations
              : null,
        ),
      );
      for (var i = 0; i < l.blocks.length; i++) {
        final b = l.blocks[i];
        if ((b.textOlChiki != null && b.textOlChiki!.isNotEmpty) ||
            (b.textLatin != null && b.textLatin!.isNotEmpty)) {
          final dataMeaning = b.data?['meaning'] as String?;
          final dataTrans = b.data?['translation'] as String?;
          final meaningEn =
              (b.data?['meaning_en'] as String?) ??
              dataMeaning ??
              dataTrans ??
              b.textLatin ??
              '';

          final customTranslations = <String, String>{};
          if (b.data != null) {
            for (final k in ['bn', 'hi', 'or', 'en']) {
              final val = b.data!['meaning_$k'] as String?;
              if (val != null && val.trim().isNotEmpty) {
                customTranslations[k] = val.trim();
              }
            }
          }

          final customTransliterations = <String, String>{};
          if (b.textBengali != null && b.textBengali!.trim().isNotEmpty) {
            customTransliterations['bn'] = b.textBengali!.trim();
          }
          if (b.textHindi != null && b.textHindi!.trim().isNotEmpty) {
            customTransliterations['hi'] = b.textHindi!.trim();
          }
          if (b.textOdia != null && b.textOdia!.trim().isNotEmpty) {
            customTransliterations['or'] = b.textOdia!.trim();
          }

          entries.add(
            TranslationEntry(
              id: '${l.id}_block_$i',
              kind: TranslationKind.lesson,
              textOlChiki: b.textOlChiki ?? '',
              textLatin: b.textLatin ?? '',
              englishMeaning: meaningEn,
              pronunciation: b.data?['pronunciation'] as String?,
              category: l.titleLatin,
              audioUrl: b.audioUrl,
              customTranslations: customTranslations.isNotEmpty
                  ? customTranslations
                  : null,
              customTransliterations: customTransliterations.isNotEmpty
                  ? customTransliterations
                  : null,
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
          englishMeaning: r.contentLatin.isNotEmpty
              ? r.contentLatin
              : r.titleLatin,
          category: r.category ?? r.categoryId,
          audioUrl: r.audioUrl,
        ),
      );
    }
  });

  return entries;
});
