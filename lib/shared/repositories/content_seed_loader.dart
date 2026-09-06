import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/models/content_item_extensions.dart';

/// Loads and caches bundled seed content items from offline asset JSON files.
class ContentSeedLoader {
  static List<ContentItem>? _cachedBundledSentenceLessons;
  static List<ContentItem>? _cachedBundledVocabLessons;
  static List<ContentItem>? _cachedBundledSentences;
  static List<ContentItem>? _cachedBundledWords;

  static Future<List<ContentItem>> loadBundledSeedItems(
    ContentKind kind,
    String? categoryId,
  ) async {
    try {
      if (kind == ContentKind.lesson) {
        final List<ContentItem> allLessons = [];

        // 1. Sentence & Grammar & Folktale Lessons (23 lessons)
        if (_cachedBundledSentenceLessons == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/sentence_lessons.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledSentenceLessons = raw
                .cast<Map<String, dynamic>>()
                .map((map) {
                  final lesson = LessonModel.fromJson(map);
                  return ContentItem(
                    id: lesson.id,
                    kind: ContentKind.lesson,
                    categoryId: lesson.categoryId.isNotEmpty
                        ? lesson.categoryId
                        : 'cat_sentences',
                    title: lesson.titleLatin,
                    titleOlChiki: lesson.titleOlChiki.isNotEmpty
                        ? lesson.titleOlChiki
                        : null,
                    subtitle: lesson.description,
                    order: lesson.order,
                    durationSeconds: lesson.estimatedMinutes * 60,
                    blocks: lesson.blocks
                        .asMap()
                        .entries
                        .map((e) => e.value.toContentBlock(e.key))
                        .toList(),
                    isPublished: true,
                    updatedAt: DateTime(2026, 8, 30),
                  );
                })
                .toList();
          } catch (e, stack) {
            _cachedBundledSentenceLessons = [];
            _logSeedLoadFailure('sentence lessons', e, stack);
          }
        }

        // 2. Vocab Lessons (14 lessons)
        if (_cachedBundledVocabLessons == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/vocab_lessons.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledVocabLessons = raw.cast<Map<String, dynamic>>().map((
              map,
            ) {
              final lesson = LessonModel.fromJson(map);
              return ContentItem(
                id: lesson.id,
                kind: ContentKind.lesson,
                categoryId: lesson.categoryId.isNotEmpty
                    ? lesson.categoryId
                    : 'cat_vocab',
                title: lesson.titleLatin,
                titleOlChiki: lesson.titleOlChiki.isNotEmpty
                    ? lesson.titleOlChiki
                    : null,
                subtitle: lesson.description,
                order: lesson.order,
                durationSeconds: lesson.estimatedMinutes * 60,
                blocks: lesson.blocks
                    .asMap()
                    .entries
                    .map((e) => e.value.toContentBlock(e.key))
                    .toList(),
                isPublished: true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledVocabLessons = [];
            _logSeedLoadFailure('lessons', e, stack);
          }
        }

        allLessons.addAll(_cachedBundledSentenceLessons ?? []);
        allLessons.addAll(_cachedBundledVocabLessons ?? []);

        if (categoryId != null && categoryId.isNotEmpty) {
          return allLessons.where((l) {
            if (categoryId == 'cat_sentences' ||
                categoryId == 'seed_sentences' ||
                categoryId.contains('sentence')) {
              return l.categoryId == 'cat_sentences' ||
                  l.categoryId == 'seed_sentences' ||
                  l.id.contains('sentence') ||
                  l.id.contains('grammar') ||
                  l.id.contains('story');
            }
            if (categoryId == 'cat_vocab' ||
                categoryId == 'cat_words' ||
                categoryId == 'seed_words' ||
                categoryId.contains('vocab') ||
                categoryId.contains('word')) {
              return l.categoryId == 'cat_vocab' ||
                  l.categoryId == 'cat_words' ||
                  l.categoryId == 'seed_words' ||
                  l.id.contains('vocab');
            }
            return l.categoryId == categoryId;
          }).toList();
        }
        return allLessons;
      }

      if (kind == ContentKind.sentence) {
        if (_cachedBundledSentences == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/sentences.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledSentences = raw.cast<Map<String, dynamic>>().map((s) {
              return ContentItem(
                id: s['id'] as String? ?? '',
                kind: ContentKind.sentence,
                categoryId: s['category'] as String? ?? 'cat_sentences',
                category: s['category'] as String? ?? 'General',
                title: s['sentenceLatin'] as String? ?? '',
                titleOlChiki: s['sentenceOlChiki'] as String?,
                olChiki: s['sentenceOlChiki'] as String?,
                subtitle: s['meaning'] as String?,
                order: s['order'] as int? ?? 1,
                audioUrl: s['audioUrl'] as String? ?? s['audio_url'] as String?,
                blocks: const [],
                tags: [
                  if (s['usage'] != null) s['usage'] as String,
                  if (s['pronunciation'] != null)
                    'pronunciation:${s['pronunciation']}',
                ],
                isPublished: s['isActive'] as bool? ?? true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledSentences = [];
            _logSeedLoadFailure('sentences', e, stack);
          }
        }
        return _cachedBundledSentences ?? [];
      }

      if (kind == ContentKind.word) {
        if (_cachedBundledWords == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/words.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledWords = raw.cast<Map<String, dynamic>>().map((w) {
              return ContentItem(
                id: w['id'] as String? ?? '',
                kind: ContentKind.word,
                categoryId: w['category'] as String? ?? 'cat_vocab',
                category: w['category'] as String? ?? 'General',
                title: w['wordLatin'] as String? ?? '',
                titleOlChiki: w['wordOlChiki'] as String?,
                olChiki: w['wordOlChiki'] as String?,
                subtitle: w['meaning'] as String?,
                order: w['order'] as int? ?? 1,
                audioUrl: w['audioUrl'] as String? ?? w['audio_url'] as String?,
                blocks: const [],
                tags: [
                  if (w['pronunciation'] != null)
                    'pronunciation:${w['pronunciation']}',
                ],
                isPublished: w['isActive'] as bool? ?? true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledWords = [];
            _logSeedLoadFailure('words', e, stack);
          }
        }
        return _cachedBundledWords ?? [];
      }
    } catch (e, stack) {
      _logSeedLoadFailure('bundled seed', e, stack);
    }
    return [];
  }

  static void _logSeedLoadFailure(String what, Object e, StackTrace stack) {
    AppLogger.error(
      'ContentSeedLoader: failed to load bundled seed $what: $e',
      name: 'ContentSeedLoader',
    );
    CrashReporting.recordError(e, stack);
  }
}
