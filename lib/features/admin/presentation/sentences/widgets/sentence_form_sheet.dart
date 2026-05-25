import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_modal_sheet.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/providers/providers.dart';

class SentenceFormSheet extends ConsumerStatefulWidget {
  final SentenceModel? sentence;
  final String? initialCategory;
  const SentenceFormSheet({super.key, this.sentence, this.initialCategory});

  static void show(
    BuildContext context,
    WidgetRef ref,
    SentenceModel? sentence, {
    String? initialCategory,
  }) {
    showAdminBottomSheet(
      context: context,
      builder: (_) => SentenceFormSheet(
        sentence: sentence,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  ConsumerState<SentenceFormSheet> createState() => _SentenceFormSheetState();
}

class _SentenceFormSheetState extends ConsumerState<SentenceFormSheet> {
  ContentItem? _initialItem;

  @override
  void initState() {
    super.initState();
    final s = widget.sentence;
    if (s != null) {
      final hasMedia = s.imageUrl != null || s.animationUrl != null;
      final blocks = <ContentBlock>[];
      if (s.meaning.isNotEmpty) {
        blocks.add(TextBlock(id: 'meaning', order: 0, markdown: s.meaning));
      }
      if (s.usage != null && s.usage!.isNotEmpty) {
        blocks.add(TextBlock(id: 'usage', order: 1, markdown: s.usage!));
      }
      if (s.audioUrl != null && s.audioUrl!.isNotEmpty) {
        blocks.add(
          AudioBlock(
            id: 'pronunciation_audio',
            order: blocks.length,
            media: ContentMedia(
              url: s.audioUrl!,
              fileId: '',
              kind: ContentMediaKind.audio,
            ),
            transcript: s.pronunciation,
          ),
        );
      }

      _initialItem = ContentItem(
        id: s.id,
        kind: ContentKind.sentence,
        categoryId: s.category ?? widget.initialCategory ?? '',
        title: s.sentenceLatin,
        titleOlChiki: s.sentenceOlChiki,
        olChiki: s.sentenceOlChiki,
        subtitle: s.pronunciation,
        heroMedia: hasMedia
            ? ContentMedia(
                url: s.animationUrl ?? s.imageUrl!,
                fileId: '',
                kind: s.animationUrl != null
                    ? ContentMediaKind.lottie
                    : ContentMediaKind.image,
              )
            : null,
        blocks: blocks,
        order: s.order,
        isPublished: s.isActive,
        difficulty: s.themeColor,
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
              content: Text('Failed to save sentence: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(sentencesProvider);
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
                widget.sentence == null ? 'New Sentence' : 'Edit Sentence',
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
              kind: ContentKind.sentence,
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
