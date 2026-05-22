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
  final String
  unlockMode; // 'free', 'paid_only', 'review_or_paid', 'review_only'
  final int priceInr;
  final int previewLessonCount;
  final String? courseDescription;
  final String? courseOutcome;
  final String? courseHeroImageUrl;

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
    this.unlockMode = 'free',
    this.priceInr = 0,
    this.previewLessonCount = 3,
    this.courseDescription,
    this.courseOutcome,
    this.courseHeroImageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return CategoryModel(
      id: docId ?? data['id'] as String? ?? data['\$id'] as String? ?? '',
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
      unlockMode: data['unlockMode'] as String? ?? 'free',
      priceInr: data['priceInr'] as int? ?? 0,
      previewLessonCount: data['previewLessonCount'] as int? ?? 3,
      courseDescription: data['courseDescription'] as String?,
      courseOutcome: data['courseOutcome'] as String?,
      courseHeroImageUrl: data['courseHeroImageUrl'] as String?,
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
}
