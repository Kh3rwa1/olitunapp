// ============== SENTENCE MODEL ==============
class SentenceModel {
  final String id;
  final String sentenceOlChiki;
  final String sentenceLatin;
  final String meaning;
  final String? usage;
  final String? category;
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  SentenceModel({
    required this.id,
    required this.sentenceOlChiki,
    required this.sentenceLatin,
    required this.meaning,
    this.usage,
    this.category,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.pronunciation,
    this.order = 0,
    this.isActive = true,
  });

  factory SentenceModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return SentenceModel(
      id: docId ?? data['id'] as String? ?? '',
      sentenceOlChiki: data['sentenceOlChiki'] as String? ?? '',
      sentenceLatin: data['sentenceLatin'] as String? ?? '',
      meaning: data['meaning'] as String? ?? '',
      usage: data['usage'] as String?,
      category: data['category'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      pronunciation: data['pronunciation'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentenceOlChiki': sentenceOlChiki,
      'sentenceLatin': sentenceLatin,
      'meaning': meaning,
      'usage': usage,
      'category': category,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'pronunciation': pronunciation,
      'order': order,
      'isActive': isActive,
    };
  }
}
