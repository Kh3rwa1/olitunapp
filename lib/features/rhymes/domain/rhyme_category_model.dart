class RhymeCategoryModel {
  final String id;
  final String nameOlChiki;
  final String nameLatin;
  final String iconName;
  final int order;

  RhymeCategoryModel({
    required this.id,
    required this.nameOlChiki,
    required this.nameLatin,
    required this.iconName,
    required this.order,
  });

  factory RhymeCategoryModel.fromJson(Map<String, dynamic> json) {
    return RhymeCategoryModel(
      id: json['id'] as String,
      nameOlChiki: json['nameOlChiki'] as String,
      nameLatin: json['nameLatin'] as String,
      iconName: json['iconName'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameOlChiki': nameOlChiki,
      'nameLatin': nameLatin,
      'iconName': iconName,
      'order': order,
    };
  }
}

