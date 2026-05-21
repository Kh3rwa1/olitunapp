import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/logging/app_logger.dart';

class BakhedLyricLine {
  final int lineIndex;
  final int startMs;
  final int endMs;
  final String olChiki;
  final String latin;
  final String meaning;

  const BakhedLyricLine({
    required this.lineIndex,
    required this.startMs,
    required this.endMs,
    required this.olChiki,
    required this.latin,
    required this.meaning,
  });

  factory BakhedLyricLine.fromJson(Map<String, dynamic> json) {
    return BakhedLyricLine(
      lineIndex: _readInt(json['lineIndex']),
      startMs: _readInt(json['startMs']),
      endMs: _readInt(json['endMs']),
      olChiki: _readString(json['olChiki']),
      latin: _readString(json['latin']),
      meaning: _readString(json['meaning']),
    );
  }
}

class BakhedVocabularyItem {
  final String olChiki;
  final String latin;
  final String meaning;
  final String audioFileId;
  final int sortOrder;

  const BakhedVocabularyItem({
    required this.olChiki,
    required this.latin,
    required this.meaning,
    required this.audioFileId,
    required this.sortOrder,
  });

  factory BakhedVocabularyItem.fromJson(Map<String, dynamic> json) {
    return BakhedVocabularyItem(
      olChiki: _readString(json['olChiki']),
      latin: _readString(json['latin']),
      meaning: _readString(json['meaning']),
      audioFileId: _readString(json['audioFileId']),
      sortOrder: _readInt(json['sortOrder']),
    );
  }
}

class BakhedCulturalNote {
  final String noteId;
  final String title;
  final String body;
  final String source;

  const BakhedCulturalNote({
    required this.noteId,
    required this.title,
    required this.body,
    required this.source,
  });

  factory BakhedCulturalNote.fromJson(Map<String, dynamic> json) {
    return BakhedCulturalNote(
      noteId: _readString(json['noteId'] ?? json[r'$id']),
      title: _readString(json['title']),
      body: _readString(json['body']),
      source: _readString(json['source']),
    );
  }
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
}

final bakhedLearningContentProvider =
    FutureProvider.family<BakhedLearningContent, String>((ref, bakhedId) async {
      final trimmedId = bakhedId.trim();
      if (trimmedId.isEmpty) return BakhedLearningContent.empty;

      try {
        final db = ref.read(appwriteDbServiceProvider);
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
