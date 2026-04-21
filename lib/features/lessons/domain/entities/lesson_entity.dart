import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  final String id;
  final String categoryId;
  final String titleOlChiki;
  final String titleLatin;
  final String? description;
  final int order;
  final int estimatedMinutes;
  final bool isActive;
  final Map<String, dynamic>? data;
  final List<LessonBlockEntity> blocks;

  const LessonEntity({
    required this.id,
    required this.categoryId,
    required this.titleOlChiki,
    required this.titleLatin,
    this.description,
    this.order = 0,
    this.estimatedMinutes = 5,
    this.isActive = true,
    this.data,
    this.blocks = const [],
  });

  LessonEntity copyWith({
    String? id,
    String? categoryId,
    String? titleOlChiki,
    String? titleLatin,
    String? description,
    int? order,
    int? estimatedMinutes,
    bool? isActive,
    Map<String, dynamic>? data,
    List<LessonBlockEntity>? blocks,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      titleOlChiki: titleOlChiki ?? this.titleOlChiki,
      titleLatin: titleLatin ?? this.titleLatin,
      description: description ?? this.description,
      order: order ?? this.order,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isActive: isActive ?? this.isActive,
      data: data ?? this.data,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        titleOlChiki,
        titleLatin,
        description,
        order,
        estimatedMinutes,
        isActive,
        data,
        blocks,
      ];
}

class LessonBlockEntity extends Equatable {
  final String type;
  final String? textOlChiki;
  final String? textLatin;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? data;

  const LessonBlockEntity({
    required this.type,
    this.textOlChiki,
    this.textLatin,
    this.imageUrl,
    this.audioUrl,
    this.data,
  });

  @override
  List<Object?> get props => [type, textOlChiki, textLatin, imageUrl, audioUrl, data];
}
