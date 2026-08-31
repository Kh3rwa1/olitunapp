import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.titleOlChiki,
    required super.titleLatin,
    super.iconUrl,
    super.iconName,
    super.animationUrl,
    super.gradientPreset = 'skyBlue',
    super.order = 0,
    super.isActive = true,
    super.totalLessons = 0,
    super.description,
    super.unlockMode = 'free',
    super.priceInr = 0,
    super.previewLessonCount = 3,
    super.courseDescription,
    super.courseOutcome,
    super.courseHeroImageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final resolvedId =
        docId ?? json['id'] as String? ?? json['\$id'] as String? ?? '';
    return CategoryModel(
      id: resolvedId,
      titleOlChiki: json['titleOlChiki'] as String? ?? '',
      titleLatin: json['titleLatin'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      iconName: json['iconName'] as String?,
      animationUrl: json['animationUrl'] as String?,
      gradientPreset: json['gradientPreset'] as String? ?? 'skyBlue',
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      totalLessons: json['totalLessons'] as int? ?? 0,
      description: json['description'] as String?,
      unlockMode: json['unlockMode'] as String? ?? 'free',
      priceInr: json['priceInr'] as int? ?? 0,
      previewLessonCount: json['previewLessonCount'] as int? ?? 3,
      courseDescription: json['courseDescription'] as String?,
      courseOutcome: json['courseOutcome'] as String?,
      courseHeroImageUrl: json['courseHeroImageUrl'] as String?,
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
      'unlockMode': unlockMode,
      'priceInr': priceInr,
      'previewLessonCount': previewLessonCount,
      'courseDescription': courseDescription,
      'courseOutcome': courseOutcome,
      'courseHeroImageUrl': courseHeroImageUrl,
    };
  }

  // Convenience getters for backwards compatibility
  String get titleEn => titleLatin;
  String get icon => iconName ?? 'book';
  @override
  bool get isPremium => unlockMode != 'free';

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
    String? unlockMode,
    int? priceInr,
    int? previewLessonCount,
    String? courseDescription,
    String? courseOutcome,
    String? courseHeroImageUrl,
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
      unlockMode: unlockMode ?? this.unlockMode,
      priceInr: priceInr ?? this.priceInr,
      previewLessonCount: previewLessonCount ?? this.previewLessonCount,
      courseDescription: courseDescription ?? this.courseDescription,
      courseOutcome: courseOutcome ?? this.courseOutcome,
      courseHeroImageUrl: courseHeroImageUrl ?? this.courseHeroImageUrl,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      titleOlChiki: titleOlChiki,
      titleLatin: titleLatin,
      iconUrl: iconUrl,
      iconName: iconName,
      animationUrl: animationUrl,
      gradientPreset: gradientPreset,
      order: order,
      isActive: isActive,
      totalLessons: totalLessons,
      description: description,
      unlockMode: unlockMode,
      priceInr: priceInr,
      previewLessonCount: previewLessonCount,
      courseDescription: courseDescription,
      courseOutcome: courseOutcome,
      courseHeroImageUrl: courseHeroImageUrl,
    );
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      titleOlChiki: entity.titleOlChiki,
      titleLatin: entity.titleLatin,
      iconUrl: entity.iconUrl,
      iconName: entity.iconName,
      animationUrl: entity.animationUrl,
      gradientPreset: entity.gradientPreset,
      order: entity.order,
      isActive: entity.isActive,
      totalLessons: entity.totalLessons,
      description: entity.description,
      unlockMode: entity.unlockMode,
      priceInr: entity.priceInr,
      previewLessonCount: entity.previewLessonCount,
      courseDescription: entity.courseDescription,
      courseOutcome: entity.courseOutcome,
      courseHeroImageUrl: entity.courseHeroImageUrl,
    );
  }
}
