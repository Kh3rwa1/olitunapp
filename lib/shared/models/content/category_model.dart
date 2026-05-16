// ============== CATEGORY MODEL ==============
class CategoryModel {
  final String id;
  final String titleOlChiki;
  final String titleLatin;
  final String? iconUrl;
  final String? iconName;
  final String? animationUrl;
  final String gradientPreset;
  final int order;
  final bool isActive;
  final int totalLessons;
  final String? description;

  CategoryModel({
    required this.id,
    required this.titleOlChiki,
    required this.titleLatin,
    this.iconUrl,
    this.iconName,
    this.animationUrl,
    this.gradientPreset = 'skyBlue',
    this.order = 0,
    this.isActive = true,
    this.totalLessons = 0,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return CategoryModel(
      id: docId ?? data['id'] as String? ?? '',
      titleOlChiki: data['titleOlChiki'] as String? ?? '',
      titleLatin: data['titleLatin'] as String? ?? '',
      iconUrl: data['iconUrl'] as String?,
      iconName: data['iconName'] as String?,
      animationUrl: data['animationUrl'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      totalLessons: data['totalLessons'] as int? ?? 0,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleOlChiki': titleOlChiki,
      'titleLatin': titleLatin,
      'iconUrl': iconUrl,
      'iconName': iconName,
      'animationUrl': animationUrl,
      'gradientPreset': gradientPreset,
      'order': order,
      'isActive': isActive,
      'totalLessons': totalLessons,
      'description': description,
    };
  }

  // Convenience getters for backwards compatibility
  String get titleEn => titleLatin;
  String get icon => iconName ?? 'book';

  CategoryModel copyWith({
    String? id,
    String? titleOlChiki,
    String? titleLatin,
    String? iconUrl,
    String? iconName,
    String? animationUrl,
    String? gradientPreset,
    int? order,
    bool? isActive,
    int? totalLessons,
    String? description,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      titleLatin: titleLatin ?? this.titleLatin,
      iconUrl: iconUrl ?? this.iconUrl,
      iconName: iconName ?? this.iconName,
      animationUrl: animationUrl ?? this.animationUrl,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      totalLessons: totalLessons ?? this.totalLessons,
      description: description ?? this.description,
    );
  }
}
