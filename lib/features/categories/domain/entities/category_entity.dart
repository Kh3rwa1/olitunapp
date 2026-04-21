import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
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

  const CategoryEntity({
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

  @override
  List<Object?> get props => [
        id,
        titleOlChiki,
        titleLatin,
        iconUrl,
        iconName,
        animationUrl,
        gradientPreset,
        order,
        isActive,
        totalLessons,
        description,
      ];
}
