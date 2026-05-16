// ============== FEATURED BANNER MODEL ==============
class FeaturedBannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? animationUrl;
  final String gradientPreset;
  final String? targetRoute;
  final int order;
  final bool isActive;

  FeaturedBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.animationUrl,
    this.gradientPreset = 'skyBlue',
    this.targetRoute,
    this.order = 0,
    this.isActive = true,
  });

  factory FeaturedBannerModel.fromJson(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return FeaturedBannerModel(
      id: docId ?? data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      imageUrl: data['imageUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      gradientPreset: data['gradientPreset'] as String? ?? 'skyBlue',
      targetRoute: data['targetRoute'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'animationUrl': animationUrl,
      'gradientPreset': gradientPreset,
      'targetRoute': targetRoute,
      'order': order,
      'isActive': isActive,
    };
  }

  FeaturedBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? animationUrl,
    String? gradientPreset,
    String? targetRoute,
    int? order,
    bool? isActive,
  }) {
    return FeaturedBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      targetRoute: targetRoute ?? this.targetRoute,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}
