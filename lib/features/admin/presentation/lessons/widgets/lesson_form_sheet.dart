import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_modal_sheet.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialItem();
  }

  Future<void> _loadInitialItem() async {
    final l = widget.lesson;
    if (l == null) return;

    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(contentRepositoryProvider);
    final res = await repo.get(ContentKind.lesson, l.id);

    res.fold(
      (failure) {
        // Fallback to legacy synthesis
        _synthesizeLegacy(l);
      },
      (item) {
        if (item.blocks.isNotEmpty) {
          _initialItem = item;
        } else {
          // Fallback to legacy synthesis for blocks, but read heroMedia and subtitle directly from the fetched item
          _synthesizeLegacy(
            l,
            heroMedia: item.heroMedia,
            subtitle: item.subtitle,
          );
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _synthesizeLegacy(
    LessonEntity l, {
    ContentMedia? heroMedia,
    String? subtitle,
  }) {
    final blocks = l.blocks
        .asMap()
        .entries
        .map((e) => e.value.toContentBlock(e.key))
        .toList();

    _initialItem = ContentItem(
      id: l.id,
      kind: ContentKind.lesson,
      categoryId: l.categoryId,
      title: l.titleLatin,
      titleOlChiki: l.titleOlChiki,
      subtitle: subtitle ?? l.description,
      heroMedia: heroMedia,
      blocks: blocks,
      order: l.order,
      isPublished: l.isActive,
      updatedAt: DateTime.now(),
    );
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
                tooltip: 'Close form',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ContentForm(
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
