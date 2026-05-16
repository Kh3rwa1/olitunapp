// ============== NUMBER MODEL ==============
class NumberModel {
  final String id;
  final String numeral; // Ol Chiki numeral: ᱑, ᱒, etc.
  final int value; // Numeric value: 1, 2, etc.
  final String nameOlChiki; // Name in Ol Chiki: ᱢᱤᱛ
  final String nameLatin; // Name in Latin: mit (one)
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final String? pronunciation;
  final int order;
  final bool isActive;

  NumberModel({
    required this.id,
    required this.numeral,
    required this.value,
    required this.nameOlChiki,
    required this.nameLatin,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.pronunciation,
    this.order = 0,
    this.isActive = true,
  });

  factory NumberModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return NumberModel(
      id: docId ?? data['id'] as String? ?? '',
      numeral: data['numeral'] as String? ?? '',
      value: data['value'] as int? ?? 0,
      nameOlChiki: data['nameOlChiki'] as String? ?? '',
      nameLatin: data['nameLatin'] as String? ?? '',
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
      'numeral': numeral,
      'value': value,
      'nameOlChiki': nameOlChiki,
      'nameLatin': nameLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'pronunciation': pronunciation,
      'order': order,
      'isActive': isActive,
    };
  }
}
