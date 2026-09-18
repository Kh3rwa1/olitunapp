import 'package:appwrite/appwrite.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/cache_service.dart';

class BakhedLyricLine extends Equatable {
  final String id;
  final int lineIndex;
  final int startMs;
  final int endMs;
  final String olChiki;
  final String latin;
  final String meaning;

  const BakhedLyricLine({
    required this.id,
    required this.lineIndex,
    required this.startMs,
    required this.endMs,
    required this.olChiki,
    required this.latin,
    required this.meaning,
  });

  factory BakhedLyricLine.fromJson(Map<String, dynamic> json) {
    return BakhedLyricLine(
      id: _readString(json['id'] ?? json['\$id']),
      lineIndex: _readInt(json['lineIndex']),
      startMs: _readInt(json['startMs']),
      endMs: _readInt(json['endMs']),
      olChiki: _readString(json['olChiki']),
      latin: _readString(json['latin']),
      meaning: _readString(json['meaning']),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'lineIndex': lineIndex,
      'startMs': startMs,
      'endMs': endMs,
      'olChiki': olChiki,
      'latin': latin,
      'meaning': meaning,
    };
  }

  Map<String, dynamic> toJson(String bakhedId) {
    return {
      if (id.isNotEmpty) 'id': id,
      'bakhedId': bakhedId,
      'lineIndex': lineIndex,
      'startMs': startMs,
      'endMs': endMs,
      'olChiki': olChiki,
      'latin': latin,
      'meaning': meaning,
    };
  }

  BakhedLyricLine copyWith({
    String? id,
    int? lineIndex,
    int? startMs,
    int? endMs,
    String? olChiki,
    String? latin,
    String? meaning,
  }) {
    return BakhedLyricLine(
      id: id ?? this.id,
      lineIndex: lineIndex ?? this.lineIndex,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      olChiki: olChiki ?? this.olChiki,
      latin: latin ?? this.latin,
      meaning: meaning ?? this.meaning,
    );
  }

  @override
  List<Object?> get props => [
    id,
    lineIndex,
    startMs,
    endMs,
    olChiki,
    latin,
    meaning,
  ];
}

class BakhedVocabularyItem extends Equatable {
  final String id;
  final String olChiki;
  final String latin;
  final String meaning;
  final String audioFileId;
  final int sortOrder;

  const BakhedVocabularyItem({
    required this.id,
    required this.olChiki,
    required this.latin,
    required this.meaning,
    required this.audioFileId,
    required this.sortOrder,
  });

  factory BakhedVocabularyItem.fromJson(Map<String, dynamic> json) {
    return BakhedVocabularyItem(
      id: _readString(json['id'] ?? json['\$id']),
      olChiki: _readString(json['olChiki']),
      latin: _readString(json['latin']),
      meaning: _readString(json['meaning']),
      audioFileId: _readString(json['audioFileId']),
      sortOrder: _readInt(json['sortOrder']),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'olChiki': olChiki,
      'latin': latin,
      'meaning': meaning,
      'audioFileId': audioFileId,
      'sortOrder': sortOrder,
    };
  }

  Map<String, dynamic> toJson(String bakhedId) {
    return {
      if (id.isNotEmpty) 'id': id,
      'bakhedId': bakhedId,
      'olChiki': olChiki,
      'latin': latin,
      'meaning': meaning,
      'audioFileId': audioFileId,
      'sortOrder': sortOrder,
    };
  }

  BakhedVocabularyItem copyWith({
    String? id,
    String? olChiki,
    String? latin,
    String? meaning,
    String? audioFileId,
    int? sortOrder,
  }) {
    return BakhedVocabularyItem(
      id: id ?? this.id,
      olChiki: olChiki ?? this.olChiki,
      latin: latin ?? this.latin,
      meaning: meaning ?? this.meaning,
      audioFileId: audioFileId ?? this.audioFileId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    olChiki,
    latin,
    meaning,
    audioFileId,
    sortOrder,
  ];
}

class BakhedCulturalNote extends Equatable {
  final String noteId;
  final String title;
  final String body;
  final String source;
  final bool isPublished;

  const BakhedCulturalNote({
    required this.noteId,
    required this.title,
    required this.body,
    required this.source,
    this.isPublished = false,
  });

  factory BakhedCulturalNote.fromJson(Map<String, dynamic> json) {
    return BakhedCulturalNote(
      noteId: _readString(json['noteId'] ?? json['id'] ?? json[r'$id']),
      title: _readString(json['title']),
      body: _readString(json['body']),
      source: _readString(json['source']),
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'noteId': noteId,
      'title': title,
      'body': body,
      'source': source,
      'isPublished': isPublished,
    };
  }

  Map<String, dynamic> toJson(String bakhedId) {
    return {
      if (noteId.isNotEmpty) 'id': noteId,
      'noteId': noteId,
      'bakhedId': bakhedId,
      'title': title,
      'body': body,
      'source': source,
      'isPublished': isPublished,
    };
  }

  BakhedCulturalNote copyWith({
    String? noteId,
    String? title,
    String? body,
    String? source,
    bool? isPublished,
  }) {
    return BakhedCulturalNote(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      body: body ?? this.body,
      source: source ?? this.source,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  @override
  List<Object?> get props => [noteId, title, body, source, isPublished];
}

class BakhedLearningContent {
  final List<BakhedLyricLine> lyrics;
  final List<BakhedVocabularyItem> vocabulary;
  final List<BakhedCulturalNote> culturalNotes;

  const BakhedLearningContent({
    this.lyrics = const [],
    this.vocabulary = const [],
    this.culturalNotes = const [],
  });

  static const empty = BakhedLearningContent();

  bool get isEmpty =>
      lyrics.isEmpty && vocabulary.isEmpty && culturalNotes.isEmpty;

  Map<String, dynamic> toCacheJson() {
    return {
      'lyrics': lyrics.map((line) => line.toCacheJson()).toList(),
      'vocabulary': vocabulary.map((item) => item.toCacheJson()).toList(),
      'culturalNotes': culturalNotes.map((note) => note.toCacheJson()).toList(),
    };
  }

  factory BakhedLearningContent.fromCacheJson(Map<String, dynamic> json) {
    List<T> decodeList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }

    return BakhedLearningContent(
      lyrics: decodeList(json['lyrics'], BakhedLyricLine.fromJson),
      vocabulary: decodeList(json['vocabulary'], BakhedVocabularyItem.fromJson),
      culturalNotes: decodeList(
        json['culturalNotes'],
        BakhedCulturalNote.fromJson,
      ),
    );
  }
}

String _bakhedContentCacheKey(String bakhedId) => 'bakhed_content_$bakhedId';

Future<BakhedLearningContent> _fetchBakhedLearningContent(
  AppwriteDbService db,
  String trimmedId,
) async {
  final results = await Future.wait([
    db.listDocuments(
      'bakhed_lyrics',
      queries: [
        Query.equal('bakhedId', trimmedId),
        Query.orderAsc('lineIndex'),
        Query.limit(100),
      ],
    ),
    db.listDocuments(
      'bakhed_vocabulary',
      queries: [
        Query.equal('bakhedId', trimmedId),
        Query.orderAsc('sortOrder'),
        Query.limit(100),
      ],
    ),
    db.listDocuments(
      'bakhed_cultural_notes',
      queries: [
        Query.equal('bakhedId', trimmedId),
        Query.equal('isPublished', true),
        Query.limit(20),
      ],
    ),
  ]);

  return BakhedLearningContent(
    lyrics: results[0].map(BakhedLyricLine.fromJson).toList(),
    vocabulary: results[1].map(BakhedVocabularyItem.fromJson).toList(),
    culturalNotes: results[2].map(BakhedCulturalNote.fromJson).toList(),
  );
}

final bakhedLearningContentProvider =
    FutureProvider.family<BakhedLearningContent, String>((ref, bakhedId) async {
      final trimmedId = bakhedId.trim();
      if (trimmedId.isEmpty) return BakhedLearningContent.empty;
      final cacheKey = _bakhedContentCacheKey(trimmedId);

      // Stale-while-revalidate: serve Hive instantly (even past TTL) so
      // Bakhed detail opens offline; refresh in the background only when past
      // TTL, then rebuild once with fresh data. The freshness gate prevents
      // a refresh → invalidateSelf → refresh rebuild loop.
      final fresh = await CacheService.getStrictlyFresh(
        cacheKey,
        BakhedLearningContent.fromCacheJson,
      );
      final cached =
          fresh ??
          await CacheService.get(
            cacheKey,
            BakhedLearningContent.fromCacheJson,
          );
      if (cached != null && !cached.isEmpty) {
        if (fresh == null) {
          Future(() async {
            try {
              final db = ref.read(appwriteDbServiceProvider);
              final latest = await _fetchBakhedLearningContent(db, trimmedId);
              if (!latest.isEmpty) {
                await CacheService.set(cacheKey, latest.toCacheJson());
                ref.invalidateSelf();
              }
            } catch (_) {
              // Offline: the stale copy above stays on screen.
            }
          });
        }
        return cached;
      }

      try {
        final db = ref.read(appwriteDbServiceProvider);
        final content = await _fetchBakhedLearningContent(db, trimmedId);
        if (!content.isEmpty) {
          await CacheService.set(cacheKey, content.toCacheJson());
        }
        return content;
      } catch (e) {
        AppLogger.debug('Bakhed content fallback for $trimmedId: $e');
        return BakhedLearningContent.empty;
      }
    });

String _readString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
