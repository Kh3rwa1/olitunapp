import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_modal_sheet.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/providers/providers.dart';

class LessonFormSheet extends ConsumerStatefulWidget {
  final LessonEntity? lesson;
  final String? initialCategoryId;

  const LessonFormSheet({super.key, this.lesson, this.initialCategoryId});

  static void show(
    BuildContext context,
    WidgetRef ref,
    LessonEntity? lesson, {
    String? initialCategoryId,
  }) {
    showAdminBottomSheet(
      context: context,
      builder: (_) =>
          LessonFormSheet(lesson: lesson, initialCategoryId: initialCategoryId),
    );
  }

  @override
  ConsumerState<LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends ConsumerState<LessonFormSheet> {
  ContentItem? _initialItem;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    if (l != null) {
      final heroMediaUrl =
          l.data?['heroMediaUrl'] ??
          l.data?['videoUrl'] ??
          l.data?['animationUrl'] ??
          l.data?['imageUrl'] ??
          l.data?['thumbnailUrl'] as String?;
      final heroMediaType = l.data?['heroMediaType'] as String?;
      final heroPosterUrl = l.data?['heroPosterUrl'] as String?;

      ContentMedia? heroMedia;
      if (heroMediaUrl != null && heroMediaUrl.isNotEmpty) {
        heroMedia = ContentMedia(
          url: heroMediaUrl,
          fileId: '',
          kind: heroMediaType != null
              ? ContentMediaKind.fromString(heroMediaType)
              : ContentMediaKind.image,
          posterUrl: heroPosterUrl,
        );
      }

      final blocks = <ContentBlock>[];
      for (int i = 0; i < l.blocks.length; i++) {
        final b = l.blocks[i];
        if (b.type == 'text') {
          blocks.add(
            TextBlock(
              id: const Uuid().v4(),
              order: i,
              markdown: b.textLatin ?? '',
            ),
          );
        } else if (b.type == 'image') {
          blocks.add(
            ImageBlock(
              id: const Uuid().v4(),
              order: i,
              media: ContentMedia(
                url: b.imageUrl ?? '',
                fileId: '',
                kind: ContentMediaKind.image,
              ),
            ),
          );
        } else if (b.type == 'audio') {
          blocks.add(
            AudioBlock(
              id: const Uuid().v4(),
              order: i,
              media: ContentMedia(
                url: b.audioUrl ?? '',
                fileId: '',
                kind: ContentMediaKind.audio,
              ),
            ),
          );
        }
      }

      _initialItem = ContentItem(
        id: l.id,
        kind: ContentKind.lesson,
        categoryId: l.categoryId,
        title: l.titleLatin,
        titleOlChiki: l.titleOlChiki,
        subtitle: l.description,
        heroMedia: heroMedia,
        blocks: blocks,
        order: l.order,
        isPublished: l.isActive,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _onSubmit(ContentItem item) async {
    final repo = ref.read(contentRepositoryProvider);
    final res = await repo.upsert(item);

    if (mounted) {
      res.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save lesson: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(lessonNotifierProvider);
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.lesson == null ? 'New Subcategory' : 'Edit Subcategory',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ContentForm(
              kind: ContentKind.lesson,
              categoryId: widget.initialCategoryId,
              initial: _initialItem,
              onSubmit: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
