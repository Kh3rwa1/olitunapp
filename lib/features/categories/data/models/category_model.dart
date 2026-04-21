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
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return CategoryModel(
      id: docId ?? json['id'] as String? ?? json['$id'] as String? ?? '',
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
    );
  }
}
