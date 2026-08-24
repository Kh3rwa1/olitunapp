import 'dart:convert';
import 'package:itun/shared/models/content_item.dart';

class RhymeModel {
  final String id;
  final String titleOlChiki;
  final String titleLatin;
  final String contentOlChiki;
  final String contentLatin;
  final String? audioUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? category;
  final List<String> tags;
  final bool isFeatured;
  final String? coverMediaType;
  final ContentMedia? heroMedia;

  RhymeModel({
    required this.id,
    required this.titleOlChiki,
    required this.titleLatin,
    required this.contentOlChiki,
    required this.contentLatin,
    this.audioUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.category,
    this.tags = const [],
    this.isFeatured = false,
    this.coverMediaType,
    this.heroMedia,
  });

  factory RhymeModel.fromJson(Map<String, dynamic> json) {
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

    return RhymeModel(
      id: _readString(json, 'id') ?? _readString(json, r'$id') ?? '',
      titleOlChiki: _readString(json, 'titleOlChiki') ?? '',
      titleLatin: _readString(json, 'titleLatin') ?? '',
      contentOlChiki: _readString(json, 'contentOlChiki') ?? '',
      contentLatin: _readString(json, 'contentLatin') ?? '',
      audioUrl: _readString(json, 'audioUrl'),
      thumbnailUrl: _readString(json, 'thumbnailUrl'),
      categoryId: _readString(json, 'categoryId'),
      category: _readString(json, 'category'),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isFeatured:
          json['isFeatured'] == true ||
          (json['data'] is Map && json['data']['isFeatured'] == true),
      coverMediaType:
          _readString(json, 'coverMediaType') ??
          (parsedHeroMedia != null ? 'image' : null),
      heroMedia: parsedHeroMedia,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'contentOlChiki': contentOlChiki,
      'contentLatin': contentLatin,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
      'categoryId': categoryId,
      'category': category,
      'tags': tags,
      'isFeatured': isFeatured,
      if (coverMediaType != null) 'coverMediaType': coverMediaType,
      if (heroMedia != null) 'heroMedia': heroMedia!.toJson(),
    };
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
