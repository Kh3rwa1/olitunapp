// ============== WORD MODEL ==============
class WordModel {
  final String id;
  final String wordOlChiki; // Word in Ol Chiki: ᱡᱚᱦᱟᱨ
  final String wordLatin; // Word in Latin: johar
  final String meaning; // English meaning: hello
  final String? usage; // Usage hint
  final String? category; // greetings, family, etc.
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  WordModel({
    required this.id,
    required this.wordOlChiki,
    required this.wordLatin,
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

  factory WordModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return WordModel(
      id: docId ?? data['id'] as String? ?? '',
      wordOlChiki: data['wordOlChiki'] as String? ?? '',
      wordLatin: data['wordLatin'] as String? ?? '',
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
      'wordOlChiki': wordOlChiki,
      'wordLatin': wordLatin,
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
