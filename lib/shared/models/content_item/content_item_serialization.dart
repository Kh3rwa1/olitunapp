import 'dart:convert';
import 'package:itun/core/logging/app_logger.dart';

import 'content_block.dart';
import 'content_enums.dart';
import 'content_item_model.dart';
import 'content_media.dart';
import 'tracing_models.dart';

/// Helper parser and serializer for ContentItem to keep model definition focused and clean.
class ContentItemSerialization {
  static String? extractFileIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(r'/files/([^/]+)/view');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  static String? coerceTagsToLegacyString(List<String>? tags) {
    if (tags == null || tags.isEmpty) return null;
    final joined = tags.where((t) => t.trim().isNotEmpty).join(',');
    if (joined.isEmpty) return null;
    return joined.length <= 50 ? joined : joined.substring(0, 50);
  }

  static ContentItem fromJson(
    Map<String, dynamic> json, [
    String? docId,
    ContentKind? expectedKind,
  ]) {
    final rawKind = expectedKind?.name ?? json['kind'] as String? ?? 'lesson';
    final parsedKind = ContentKind.fromString(rawKind);

    final rawTracing = json['tracing'];
    TracingConfig? parsedTracing;
    if (rawTracing != null) {
      if (rawTracing is String) {
        if (rawTracing.isNotEmpty) {
          try {
            parsedTracing = TracingConfig.fromJson(
              jsonDecode(rawTracing) as Map<String, dynamic>,
            );
          } catch (_) {}
        }
      } else if (rawTracing is Map<String, dynamic>) {
        parsedTracing = TracingConfig.fromJson(rawTracing);
      }
    }

    final rawHeroMedia = json['hero_media'] ?? json['heroMedia'];
    ContentMedia? parsedHeroMedia;
    if (rawHeroMedia != null) {
      if (rawHeroMedia is String) {
        if (rawHeroMedia.isNotEmpty) {
          try {
            parsedHeroMedia = ContentMedia.fromJson(
              jsonDecode(rawHeroMedia) as Map<String, dynamic>,
            );
          } catch (_) {}
        }
      } else if (rawHeroMedia is Map<String, dynamic>) {
        parsedHeroMedia = ContentMedia.fromJson(rawHeroMedia);
      }
    }
    if (parsedHeroMedia != null && parsedHeroMedia.fileId.isEmpty) {
      final extId = extractFileIdFromUrl(parsedHeroMedia.url);
      if (extId != null && extId.isNotEmpty) {
        parsedHeroMedia = ContentMedia(
          url: parsedHeroMedia.url,
          fileId: extId,
          kind: parsedHeroMedia.kind,
          posterUrl: parsedHeroMedia.posterUrl,
          durationSeconds: parsedHeroMedia.durationSeconds,
        );
      }
    }

    final rawBlocks = json['blocks'];
    List<ContentBlock> parsedBlocks = const [];
    if (rawBlocks != null) {
      if (rawBlocks is String) {
        if (rawBlocks.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawBlocks) as List<dynamic>;
            parsedBlocks = decoded
                .map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return ContentBlock.fromJson(e);
                    }
                    if (e is Map) {
                      return ContentBlock.fromJson(e.cast<String, dynamic>());
                    }
                  } catch (_) {}
                  return null;
                })
                .whereType<ContentBlock>()
                .toList();
          } catch (_) {}
        }
      } else if (rawBlocks is List<dynamic>) {
        parsedBlocks = rawBlocks
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return ContentBlock.fromJson(e);
                }
                if (e is Map) {
                  return ContentBlock.fromJson(e.cast<String, dynamic>());
                }
              } catch (_) {}
              return null;
            })
            .whereType<ContentBlock>()
            .toList();
      }
    }

    final rawUpdatedAt =
        json['updatedAt'] ?? json['updated_at'] ?? json[r'$updatedAt'];
    DateTime parsedUpdatedAt = DateTime.now();
    if (rawUpdatedAt != null) {
      if (rawUpdatedAt is String) {
        parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
      } else if (rawUpdatedAt is int) {
        parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
      }
    }

    final tagsListRaw = json['tagsList'];
    List<String> parsedTags;
    if (tagsListRaw is List) {
      parsedTags = tagsListRaw
          .cast<String>()
          .where((t) => t.trim().isNotEmpty)
          .toList();
    } else {
      final rawTags = json['tags'];
      if (rawTags is List<dynamic>) {
        parsedTags = rawTags.map((e) => e.toString()).toList();
      } else if (rawTags is String && rawTags.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTags) as List<dynamic>;
          parsedTags = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          parsedTags = rawTags
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
        }
      } else {
        parsedTags = const [];
      }
    }

    final rawCategoryId =
        json['category_id'] ??
        json['categoryId'] ??
        ((parsedKind == ContentKind.word ||
                parsedKind == ContentKind.sentence ||
                parsedKind == ContentKind.rhyme)
            ? json['category']
            : null);
    String parsedCategoryId = '';
    if (rawCategoryId is String) {
      parsedCategoryId = rawCategoryId;
    } else if (rawCategoryId is Map) {
      parsedCategoryId =
          (rawCategoryId['\$id'] ?? rawCategoryId['id'] ?? '') as String;
    }

    String? firstString(List<dynamic> values) {
      for (final value in values) {
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    }

    var resolvedTitle = firstString([json['title'], json['titleLatin']]) ?? '';
    var resolvedTitleOlChiki = firstString([
      json['title_ol_chiki'],
      json['titleOlChiki'],
    ]);
    var resolvedSubtitle = json['subtitle'] as String?;
    var resolvedOlChiki = firstString([json['ol_chiki'], json['olChiki']]);

    switch (parsedKind) {
      case ContentKind.lesson:
        resolvedTitle =
            firstString([json['title'], json['titleLatin']]) ?? resolvedTitle;
        resolvedSubtitle =
            firstString([json['subtitle'], json['description']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.letter:
        resolvedTitle =
            firstString([json['title'], json['transliterationLatin']]) ??
            resolvedTitle;
        resolvedTitleOlChiki ??= json['charOlChiki'] as String?;
        resolvedOlChiki ??= json['charOlChiki'] as String?;
        resolvedSubtitle =
            firstString([
              json['subtitle'],
              json['exampleWordLatin'],
              json['exampleWordOlChiki'],
            ]) ??
            resolvedSubtitle;
        break;
      case ContentKind.number:
        resolvedTitle =
            firstString([json['title'], json['nameLatin']]) ?? resolvedTitle;
        resolvedTitleOlChiki ??= json['nameOlChiki'] as String?;
        resolvedOlChiki ??= json['numeral'] as String?;
        break;
      case ContentKind.word:
        resolvedTitle =
            firstString([json['title'], json['wordLatin']]) ?? resolvedTitle;
        resolvedTitleOlChiki ??= json['wordOlChiki'] as String?;
        resolvedOlChiki ??= json['wordOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['meaning']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.sentence:
        resolvedTitle =
            firstString([json['title'], json['sentenceLatin']]) ??
            resolvedTitle;
        resolvedTitleOlChiki ??= json['sentenceOlChiki'] as String?;
        resolvedOlChiki ??= json['sentenceOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['meaning']]) ??
            resolvedSubtitle;
        break;
      case ContentKind.rhyme:
        resolvedTitle =
            firstString([json['title'], json['titleLatin']]) ?? resolvedTitle;
        resolvedOlChiki ??= json['contentOlChiki'] as String?;
        resolvedSubtitle =
            firstString([json['subtitle'], json['contentLatin']]) ??
            resolvedSubtitle;
        break;
    }

    if (parsedHeroMedia == null) {
      String? legacyMediaUrl;
      ContentMediaKind? legacyMediaKind;
      if (parsedKind == ContentKind.lesson) {
        legacyMediaUrl = firstString([
          json['heroMediaUrl'],
          json['thumbnailUrl'],
        ]);
        final rawMediaType = json['heroMediaType'] as String?;
        if (rawMediaType != null) {
          try {
            legacyMediaKind = ContentMediaKind.fromString(rawMediaType);
          } catch (_) {}
        }
        legacyMediaKind ??= ContentMediaKind.image;
      } else if (firstString([json['animationUrl']]) != null) {
        legacyMediaUrl = json['animationUrl'] as String;
        legacyMediaKind = ContentMediaKind.lottie;
      } else if (firstString([json['imageUrl'], json['thumbnailUrl']]) !=
          null) {
        legacyMediaUrl = firstString([json['imageUrl'], json['thumbnailUrl']]);
        legacyMediaKind = ContentMediaKind.image;
      } else if (firstString([json['audioUrl']]) != null &&
          parsedKind != ContentKind.rhyme) {
        legacyMediaUrl = json['audioUrl'] as String;
        legacyMediaKind = ContentMediaKind.audio;
      }
      if (legacyMediaUrl != null && legacyMediaKind != null) {
        final extId = extractFileIdFromUrl(legacyMediaUrl);
        parsedHeroMedia = ContentMedia(
          url: legacyMediaUrl,
          fileId: extId ?? '',
          kind: legacyMediaKind,
        );
      }
    }

    final coverMediaType =
        json['coverMediaType'] as String? ??
        (parsedHeroMedia != null ? 'image' : null);

    final parsedItem = ContentItem(
      id: docId ?? json['\$id'] as String? ?? json['id'] as String? ?? '',
      kind: parsedKind,
      categoryId: parsedCategoryId,
      title: resolvedTitle,
      titleOlChiki: resolvedTitleOlChiki,
      subtitle: resolvedSubtitle,
      olChiki: resolvedOlChiki,
      heroMedia: parsedHeroMedia,
      coverMediaType: coverMediaType,
      blocks: parsedBlocks,
      tracing: parsedTracing,
      order: json['order'] as int? ?? 0,
      isPublished:
          json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          json['isActive'] as bool? ??
          true,
      isPremium:
          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,
      tags: parsedTags,
      difficulty: json['difficulty'] as String?,
      durationSeconds:
          json['duration_seconds'] as int? ?? json['durationSeconds'] as int?,
      updatedAt: parsedUpdatedAt,
      audioUrl: json['audioUrl'] as String?,
      audioFileId: (json['audioFileId'] as String? ?? '').isNotEmpty
          ? json['audioFileId'] as String?
          : extractFileIdFromUrl(json['audioUrl'] as String?),
      durationMs: json['durationMs'] as int?,
      category: json['category'] as String?,
    );

    if (parsedKind == ContentKind.rhyme && json['audioUrl'] == null) {
      final hasAudioBlock = parsedBlocks.any((e) => e.type == 'audio');
      if (hasAudioBlock) {
        AppLogger.debug(
          'Legacy audio block detected on rhyme ${parsedItem.id}',
        );
      }
    }

    return parsedItem;
  }

  static Map<String, dynamic> toAppwrite(ContentItem item) {
    final requiresCategory =
        item.kind == ContentKind.lesson ||
        item.kind == ContentKind.word ||
        item.kind == ContentKind.sentence ||
        item.kind == ContentKind.rhyme;
    if (requiresCategory && item.categoryId.isEmpty) {
      AppLogger.debug('ContentItem ${item.id} saved without categoryId');
    }

    final resolvedTitleOlChiki =
        (item.titleOlChiki == null || item.titleOlChiki!.trim().isEmpty)
        ? item.title
        : item.titleOlChiki!;
    final encodedHeroMedia = item.heroMedia == null
        ? null
        : jsonEncode(item.heroMedia!.toJson());
    final encodedBlocks = jsonEncode(
      item.blocks.map((e) => e.toJson()).toList(),
    );
    final encodedTracing = item.tracing == null
        ? null
        : jsonEncode(item.tracing!.toJson());
    final imageUrl =
        item.heroMedia?.kind == ContentMediaKind.image ||
            item.heroMedia?.kind == ContentMediaKind.svg
        ? item.heroMedia?.url
        : null;
    final legacyAudioUrl = item.heroMedia?.kind == ContentMediaKind.audio
        ? item.heroMedia?.url
        : null;
    final animationUrl = item.heroMedia?.kind == ContentMediaKind.lottie
        ? item.heroMedia?.url
        : null;

    if (item.kind == ContentKind.rhyme &&
        item.heroMedia?.kind == ContentMediaKind.audio &&
        item.audioUrl != null) {
      AppLogger.debug(
        'WARNING: both heroMedia.kind == audio AND audioUrl are set on rhyme ${item.id}',
      );
    }

    switch (item.kind) {
      case ContentKind.lesson:
        return {
          if (item.categoryId.isNotEmpty) 'categoryId': item.categoryId,
          'titleOlChiki': resolvedTitleOlChiki,
          'titleLatin': item.title,
          'level': 'beginner',
          'description': item.subtitle ?? '',
          'order': item.order,
          'estimatedMinutes': item.durationSeconds != null
              ? (item.durationSeconds! / 60).round()
              : 5,
          'isActive': item.isPublished,
          'isPremium': item.isPremium,
          'thumbnailUrl': item.heroMedia?.url,
          'heroMediaUrl': item.heroMedia?.url,
          'heroMediaType': item.heroMedia?.kind.name,
          'heroPosterUrl': item.heroMedia?.posterUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.letter:
        return {
          'charOlChiki': item.olChiki ?? resolvedTitleOlChiki,
          'transliterationLatin': item.title,
          'order': item.order,
          'isActive': item.isPublished,
          'exampleWordLatin': item.subtitle,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.number:
        return {
          'numeral': item.olChiki ?? resolvedTitleOlChiki,
          'value': int.tryParse(item.title) ?? item.order,
          'nameOlChiki': resolvedTitleOlChiki,
          'nameLatin': item.title,
          'order': item.order,
          'isActive': item.isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.word:
        return {
          'wordOlChiki': item.olChiki ?? resolvedTitleOlChiki,
          'wordLatin': item.title,
          'meaning': item.subtitle ?? '',
          if (item.categoryId.isNotEmpty) 'category': item.categoryId,
          'order': item.order,
          'isActive': item.isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.sentence:
        return {
          'sentenceOlChiki': item.olChiki ?? resolvedTitleOlChiki,
          'sentenceLatin': item.title,
          'meaning': item.subtitle ?? '',
          if (item.categoryId.isNotEmpty) 'category': item.categoryId,
          'order': item.order,
          'isActive': item.isPublished,
          'audioUrl': legacyAudioUrl,
          'imageUrl': imageUrl,
          'animationUrl': animationUrl,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocks,
          'tracing': encodedTracing,
        };

      case ContentKind.rhyme:
        final resolvedBlocks = item.blocks
            .where((e) => e.type != 'audio')
            .toList();
        final encodedBlocksForRhyme = jsonEncode(
          resolvedBlocks.map((e) => e.toJson()).toList(),
        );
        final tagsLegacy = coerceTagsToLegacyString(item.tags);
        final tagsArray = item.tags.where((t) => t.trim().isNotEmpty).toList();
        return {
          'titleOlChiki': resolvedTitleOlChiki,
          'titleLatin': item.title,
          'contentOlChiki': item.olChiki ?? '',
          'contentLatin': item.subtitle ?? '',
          'audioUrl': item.audioUrl,
          'audioFileId': item.audioFileId,
          'durationMs': item.durationMs,
          'thumbnailUrl': item.coverMediaType == 'image'
              ? item.heroMedia?.url
              : null,
          'coverMediaType': item.coverMediaType,
          if (item.categoryId.isNotEmpty) 'categoryId': item.categoryId,
          if (item.category != null && item.category!.isNotEmpty)
            'category': item.category,
          // ignore: use_null_aware_elements
          if (tagsLegacy != null) 'tags': tagsLegacy,
          // ignore: use_null_aware_elements
          if (tagsArray.isNotEmpty) 'tagsList': tagsArray,
          'difficulty': item.difficulty ?? 'easy',
          'durationSeconds': item.durationSeconds ?? 0,
          'isPremium': item.isPremium,
          'hero_media': encodedHeroMedia,
          'blocks': encodedBlocksForRhyme,
          'tracing': encodedTracing,
        };
    }
  }
}
