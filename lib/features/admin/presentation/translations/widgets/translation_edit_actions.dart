import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/languages/indic_translations_dictionary.dart';
import '../../../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../../../core/languages/translation_override_service.dart';
import '../../../../../shared/models/catalog/lesson_entity.dart';
import '../../../../../shared/providers/providers.dart';
import '../models/translation_entry.dart';
import '../providers/translation_entries_provider.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';

/// Dictionary/transliteration helpers and the save pipeline used by
/// [TranslationEditDialog].
void suggestTranslationMeaning({
  required BuildContext context,
  required String query,
  required String lang,
  required ValueChanged<String> onMatch,
}) {
  if (query.isEmpty) return;
  final match = IndicTranslationsDictionary.lookup(query, lang);
  if (match != null && match.isNotEmpty) {
    onMatch(match);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-suggested meaning: $match'),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No dictionary entry found for "$query" in $lang'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

void autoTransliterateOlChiki({
  required BuildContext context,
  required String olChiki,
  required String lang,
  required ValueChanged<String> onTransliterated,
}) {
  if (olChiki.isEmpty) return;
  final transliterated = OlChikiMultilingualHelper.transliterateOlChiki(
    olChiki,
    lang,
  );
  if (transliterated.isNotEmpty) {
    onTransliterated(transliterated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-transliterated: $transliterated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

Future<void> saveTranslationEntry({
  required WidgetRef ref,
  required TranslationEntry entry,
  required String bnMeaning,
  required String hiMeaning,
  required String orMeaning,
  required String enMeaning,
  required String bnPron,
  required String hiPron,
  required String orPron,
}) async {
  // 1. Save to TranslationOverrideService for immediate local effect & fast fallback
  final keysToOverride = <String>{
    entry.textOlChiki.trim(),
    entry.textLatin.trim(),
    entry.englishMeaning.trim(),
  }..removeWhere((k) => k.isEmpty);

  for (final key in keysToOverride) {
    if (bnMeaning.isNotEmpty || bnPron.isNotEmpty) {
      await TranslationOverrideService.instance.setOverride(
        key: key,
        langCode: 'bn',
        meaning: bnMeaning.isNotEmpty ? bnMeaning : null,
        pronunciation: bnPron.isNotEmpty ? bnPron : null,
      );
    }
    if (hiMeaning.isNotEmpty || hiPron.isNotEmpty) {
      await TranslationOverrideService.instance.setOverride(
        key: key,
        langCode: 'hi',
        meaning: hiMeaning.isNotEmpty ? hiMeaning : null,
        pronunciation: hiPron.isNotEmpty ? hiPron : null,
      );
    }
    if (orMeaning.isNotEmpty || orPron.isNotEmpty) {
      await TranslationOverrideService.instance.setOverride(
        key: key,
        langCode: 'or',
        meaning: orMeaning.isNotEmpty ? orMeaning : null,
        pronunciation: orPron.isNotEmpty ? orPron : null,
      );
    }
    if (enMeaning.isNotEmpty) {
      await TranslationOverrideService.instance.setOverride(
        key: key,
        langCode: 'en',
        meaning: enMeaning,
      );
    }
  }

  // 2. Dual persistence to ContentRepository if it corresponds to an entity
  final repo = ref.read(contentRepositoryProvider);
  final blockMatch = RegExp(r'^(.+)_block_(\d+)$').firstMatch(entry.id);

  if (blockMatch != null) {
    final lessonId = blockMatch.group(1)!;
    final blockIdx = int.tryParse(blockMatch.group(2)!) ?? 0;
    final res = await repo.getForAdministration(ContentKind.lesson, lessonId);
    await res.fold((_) async {}, (item) async {
      final lesson = item.toLessonEntity();
      if (blockIdx < lesson.blocks.length) {
        final blocks = List<LessonBlockEntity>.from(lesson.blocks);
        final currentBlock = blocks[blockIdx];
        final blockData = Map<String, dynamic>.from(currentBlock.data ?? {});
        blockData['meaning_bn'] = bnMeaning;
        blockData['meaning_hi'] = hiMeaning;
        blockData['meaning_or'] = orMeaning;
        blockData['meaning_en'] = enMeaning;
        if (enMeaning.isNotEmpty) {
          blockData['meaning'] = enMeaning;
        }

        if (bnPron.isNotEmpty) {
          blockData['textBengali'] = bnPron;
          blockData['pronunciation_bn'] = bnPron;
          blockData['transliteration_bn'] = bnPron;
        } else {
          blockData.remove('textBengali');
          blockData.remove('pronunciation_bn');
          blockData.remove('transliteration_bn');
        }

        if (hiPron.isNotEmpty) {
          blockData['textHindi'] = hiPron;
          blockData['pronunciation_hi'] = hiPron;
          blockData['transliteration_hi'] = hiPron;
        } else {
          blockData.remove('textHindi');
          blockData.remove('pronunciation_hi');
          blockData.remove('transliteration_hi');
        }

        if (orPron.isNotEmpty) {
          blockData['textOdia'] = orPron;
          blockData['pronunciation_or'] = orPron;
          blockData['transliteration_or'] = orPron;
        } else {
          blockData.remove('textOdia');
          blockData.remove('pronunciation_or');
          blockData.remove('transliteration_or');
        }

        blocks[blockIdx] = LessonBlockEntity(
          type: currentBlock.type,
          textOlChiki: currentBlock.textOlChiki,
          textLatin: currentBlock.textLatin,
          textBengali: bnPron.isNotEmpty ? bnPron : null,
          textHindi: hiPron.isNotEmpty ? hiPron : null,
          textOdia: orPron.isNotEmpty ? orPron : null,
          imageUrl: currentBlock.imageUrl,
          audioUrl: currentBlock.audioUrl,
          data: blockData,
        );

        final contentBlocks = blocks
            .asMap()
            .entries
            .map((e) => e.value.toContentBlock(e.key))
            .toList();

        final updatedItem = item.copyWith(
          blocks: contentBlocks,
          updatedAt: DateTime.now(),
        );
        await repo.upsert(updatedItem);
      }
    });
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
    ref.invalidate(lessonNotifierProvider);
  } else if (entry.kind == TranslationKind.lesson) {
    final res = await repo.getForAdministration(ContentKind.lesson, entry.id);
    await res.fold((_) async {}, (item) async {
      final updatedItem = item.copyWith(
        subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
        updatedAt: DateTime.now(),
      );
      await repo.upsert(updatedItem);
    });
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
    ref.invalidate(lessonNotifierProvider);
  } else if (entry.kind == TranslationKind.word) {
    final res = await repo.get(ContentKind.word, entry.id);
    await res.fold((_) async {}, (item) async {
      final updatedItem = item.copyWith(
        subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
        updatedAt: DateTime.now(),
      );
      await repo.upsert(updatedItem);
    });
    ref.invalidate(contentListProvider((ContentKind.word, null)));
    ref.invalidate(wordsProvider);
  } else if (entry.kind == TranslationKind.sentence) {
    final res = await repo.get(ContentKind.sentence, entry.id);
    await res.fold((_) async {}, (item) async {
      final updatedItem = item.copyWith(
        subtitle: enMeaning.isNotEmpty ? enMeaning : item.subtitle,
        updatedAt: DateTime.now(),
      );
      await repo.upsert(updatedItem);
    });
    ref.invalidate(contentListProvider((ContentKind.sentence, null)));
    ref.invalidate(sentencesProvider);
  }

  ref.invalidate(translationEntriesProvider);
}
