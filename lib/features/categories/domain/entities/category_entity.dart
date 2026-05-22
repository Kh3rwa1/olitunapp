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
  final String
  unlockMode; // 'free', 'paid_only', 'review_or_paid', 'review_only'
  final int priceInr;
  final int previewLessonCount;
  final String? courseDescription;
  final String? courseOutcome;
  final String? courseHeroImageUrl;

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
    this.unlockMode = 'free',
    this.priceInr = 0,
    this.previewLessonCount = 3,
    this.courseDescription,
    this.courseOutcome,
    this.courseHeroImageUrl,
  });

  bool get isPremium => unlockMode != 'free';

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
    unlockMode,
    priceInr,
    previewLessonCount,
    courseDescription,
    courseOutcome,
    courseHeroImageUrl,
  ];
}
