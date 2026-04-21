import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  final String id;
  final String categoryId;
  final String titleOlChiki;
  final String titleLatin;
  final String? description;
  final int order;
  final int estimatedMinutes;
  final List<LessonBlockEntity> blocks;

  const LessonEntity({
    required this.id,
    required this.categoryId,
    required this.titleOlChiki,
    required this.titleLatin,
    this.description,
    this.order = 0,
    this.estimatedMinutes = 5,
    this.blocks = const [],
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        titleOlChiki,
        titleLatin,
        description,
        order,
        estimatedMinutes,
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
