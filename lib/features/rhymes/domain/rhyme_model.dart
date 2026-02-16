class RhymeModel {
  final String id;
  final String titleOlChiki;
  final String titleLatin;
  final String contentOlChiki;
  final String contentLatin;
  final String? audioUrl;
  final String? thumbnailUrl;
  final String? category;
  final String? subcategory;

  RhymeModel({
    required this.id,
    required this.titleOlChiki,
    required this.titleLatin,
    required this.contentOlChiki,
    required this.contentLatin,
    this.audioUrl,
    this.thumbnailUrl,
    this.category,
    this.subcategory,
  });

  factory RhymeModel.fromJson(Map<String, dynamic> json) {
    return RhymeModel(
      id: json['id'] as String,
      titleOlChiki: json['titleOlChiki'] as String,
      titleLatin: json['titleLatin'] as String,
      contentOlChiki: json['contentOlChiki'] as String,
      contentLatin: json['contentLatin'] as String,
      audioUrl: json['audioUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
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
      'category': category,
      'subcategory': subcategory,
    };
  }
}
