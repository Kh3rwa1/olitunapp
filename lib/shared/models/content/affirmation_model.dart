// ============== AFFIRMATION MODEL ==============
class AffirmationModel {
  final String id;
  final String olChikiText;
  final String santaliPhonetic;
  final String englishMeaning;
  final String? audioUrl;
  final String category; // 'identity', 'habit', 'wealth', 'culture'
  final bool isPremium;
  final int order;
  final String publishedAt;

  AffirmationModel({
    required this.id,
    required this.olChikiText,
    required this.santaliPhonetic,
    required this.englishMeaning,
    this.audioUrl,
    required this.category,
    this.isPremium = false,
    required this.order,
    required this.publishedAt,
  });

  factory AffirmationModel.fromJson(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return AffirmationModel(
      id: docId ?? data['\$id'] as String? ?? data['id'] as String? ?? '',
      olChikiText: data['olChikiText'] as String? ?? '',
      santaliPhonetic: data['santaliPhonetic'] as String? ?? '',
      englishMeaning: data['englishMeaning'] as String? ?? '',
      audioUrl: data['audioUrl'] as String?,
      category: data['category'] as String? ?? 'identity',
      isPremium: data['isPremium'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
      publishedAt: data['publishedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'olChikiText': olChikiText,
      'santaliPhonetic': santaliPhonetic,
      'englishMeaning': englishMeaning,
      'audioUrl': audioUrl,
      'category': category,
      'isPremium': isPremium,
      'order': order,
      'publishedAt': publishedAt,
    };
  }

  AffirmationModel copyWith({
    String? id,
    String? olChikiText,
    String? santaliPhonetic,
    String? englishMeaning,
    String? audioUrl,
    String? category,
    bool? isPremium,
    int? order,
    String? publishedAt,
  }) {
    return AffirmationModel(
      id: id ?? this.id,
      olChikiText: olChikiText ?? this.olChikiText,
      santaliPhonetic: santaliPhonetic ?? this.santaliPhonetic,
      englishMeaning: englishMeaning ?? this.englishMeaning,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      isPremium: isPremium ?? this.isPremium,
      order: order ?? this.order,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
