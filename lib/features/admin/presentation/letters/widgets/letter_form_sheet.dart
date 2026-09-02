import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';

class LetterFormSheet extends ConsumerStatefulWidget {
  final LetterModel? letter;
  const LetterFormSheet({super.key, this.letter});

  static void show(BuildContext context, WidgetRef ref, LetterModel? letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: LetterFormSheet(letter: letter),
        ),
      ),
    );
  }

  @override
  ConsumerState<LetterFormSheet> createState() => _LetterFormSheetState();
}

class _LetterFormSheetState extends ConsumerState<LetterFormSheet> {
  ContentItem? _initialItem;

  @override
  void initState() {
    super.initState();
    final letter = widget.letter;
    if (letter != null) {
      // Map legacy LetterModel to universal ContentItem
      final hasMedia = letter.imageUrl != null || letter.animationUrl != null;
      _initialItem = ContentItem(
        id: letter.id,
        kind: ContentKind.letter,
        categoryId: '', // will be resolved in form dropdown
        title: letter.transliterationLatin,
        titleOlChiki: letter.charOlChiki,
        olChiki: letter.charOlChiki,
        heroMedia: hasMedia
            ? ContentMedia(
                url: letter.animationUrl ?? letter.imageUrl!,
                fileId: '',
                kind: letter.animationUrl != null
                    ? ContentMediaKind.lottie
                    : ContentMediaKind.image,
              )
            : null,
        blocks: const [],
        order: letter.order,
        isPublished: letter.isActive,
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
              content: Text('Failed to save letter: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(lettersProvider);
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
                widget.letter == null ? 'New Letter' : 'Edit Letter',
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
            child: ContentForm(
              kind: ContentKind.letter,
              initial: _initialItem,
              onSubmit: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
