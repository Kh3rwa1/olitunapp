// ============== STICKER MODEL ==============
class StickerModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? category;
  final bool isActive;

  StickerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.category,
    this.isActive = true,
  });

  factory StickerModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return StickerModel(
      id: docId ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
    };
  }
}
