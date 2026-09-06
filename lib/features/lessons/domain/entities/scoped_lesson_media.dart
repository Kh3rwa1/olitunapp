import '../../../../core/media/authorized_media.dart';
import 'lesson_entity.dart';

/// Adds only lesson identity to private references in learner views. No tokens
/// enter content models, shared caches, analytics ids, or offline snapshots.
LessonEntity scopeLessonMedia(LessonEntity lesson) {
  String? scope(String? value) =>
      value == null ? null : PrivateMediaReference.scope(value, lesson.id);
  Map<String, dynamic>? scopeData(Map<String, dynamic>? data) => data == null
      ? null
      : Map<String, dynamic>.from(
          scopeLessonMediaValue(data, lesson.id) as Map,
        );
  return LessonEntity(
    id: lesson.id,
    categoryId: lesson.categoryId,
    titleOlChiki: lesson.titleOlChiki,
    titleLatin: lesson.titleLatin,
    level: lesson.level,
    description: lesson.description,
    order: lesson.order,
    estimatedMinutes: lesson.estimatedMinutes,
    isActive: lesson.isActive,
    isPreview: lesson.isPreview,
    isLocked: lesson.isLocked,
    data: scopeData(lesson.data),
    blocks: lesson.blocks
        .map(
          (block) => LessonBlockEntity(
            type: block.type,
            textOlChiki: block.textOlChiki,
            textLatin: block.textLatin,
            textBengali: block.textBengali,
            textHindi: block.textHindi,
            textOdia: block.textOdia,
            imageUrl: scope(block.imageUrl),
            audioUrl: scope(block.audioUrl),
            data: scopeData(block.data),
          ),
        )
        .toList(),
  );
}
