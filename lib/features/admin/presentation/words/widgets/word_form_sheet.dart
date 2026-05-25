import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_modal_sheet.dart';
import 'package:itun/shared/providers/providers.dart';

class WordFormSheet extends ConsumerStatefulWidget {
  final WordModel? word;
  final String? initialCategory;
  const WordFormSheet({super.key, this.word, this.initialCategory});

  static void show(
    BuildContext context,
    WidgetRef ref,
    WordModel? word, {
    String? initialCategory,
  }) {
    showAdminBottomSheet(
      context: context,
      builder: (_) =>
          WordFormSheet(word: word, initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<WordFormSheet> createState() => _WordFormSheetState();
}

class _WordFormSheetState extends ConsumerState<WordFormSheet> {
  ContentItem? _initialItem;

  @override
  void initState() {
    super.initState();
    final w = widget.word;
    if (w != null) {
      final hasMedia = w.imageUrl != null || w.animationUrl != null;
      final blocks = <ContentBlock>[];
      if (w.meaning.isNotEmpty) {
        blocks.add(TextBlock(id: 'meaning', order: 0, markdown: w.meaning));
      }
      if (w.usage != null && w.usage!.isNotEmpty) {
        blocks.add(TextBlock(id: 'usage', order: 1, markdown: w.usage!));
      }
      if (w.audioUrl != null && w.audioUrl!.isNotEmpty) {
        blocks.add(
          AudioBlock(
            id: 'pronunciation_audio',
            order: blocks.length,
            media: ContentMedia(
              url: w.audioUrl!,
              fileId: '',
              kind: ContentMediaKind.audio,
            ),
            transcript: w.pronunciation,
          ),
        );
      }

      _initialItem = ContentItem(
        id: w.id,
        kind: ContentKind.word,
        categoryId: w.category ?? widget.initialCategory ?? '',
        title: w.wordLatin,
        titleOlChiki: w.wordOlChiki,
        olChiki: w.wordOlChiki,
        subtitle: w.pronunciation,
        heroMedia: hasMedia
            ? ContentMedia(
                url: w.animationUrl ?? w.imageUrl!,
                fileId: '',
                kind: w.animationUrl != null
                    ? ContentMediaKind.lottie
                    : ContentMediaKind.image,
              )
            : null,
        blocks: blocks,
        order: w.order,
        isPublished: w.isActive,
        difficulty: w.themeColor,
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
              content: Text('Failed to save word: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(wordsProvider);
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
                widget.word == null ? 'New Word' : 'Edit Word',
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
              kind: ContentKind.word,
              categoryId: widget.initialCategory,
              initial: _initialItem,
              onSubmit: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
