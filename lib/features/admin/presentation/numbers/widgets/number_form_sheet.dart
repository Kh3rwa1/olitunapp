import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';

class NumberFormSheet extends ConsumerStatefulWidget {
  final NumberModel? number;
  const NumberFormSheet({super.key, this.number});

  static void show(BuildContext context, WidgetRef ref, NumberModel? number) {
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
          child: NumberFormSheet(number: number),
        ),
      ),
    );
  }

  @override
  ConsumerState<NumberFormSheet> createState() => _NumberFormSheetState();
}

class _NumberFormSheetState extends ConsumerState<NumberFormSheet> {
  ContentItem? _initialItem;

  @override
  void initState() {
    super.initState();
    final number = widget.number;
    if (number != null) {
      final hasMedia = number.imageUrl != null || number.animationUrl != null;
      _initialItem = ContentItem(
        id: number.id,
        kind: ContentKind.number,
        categoryId: '',
        title: number.nameLatin,
        titleOlChiki: number.nameOlChiki,
        olChiki: number.numeral,
        heroMedia: hasMedia
            ? ContentMedia(
                url: number.animationUrl ?? number.imageUrl!,
                fileId: '',
                kind: number.animationUrl != null
                    ? ContentMediaKind.lottie
                    : ContentMediaKind.image,
              )
            : null,
        blocks: const [],
        order: number.order,
        isPublished: number.isActive,
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
              content: Text('Failed to save number: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(numbersProvider);
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
                widget.number == null ? 'New Number' : 'Edit Number',
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
              kind: ContentKind.number,
              initial: _initialItem,
              onSubmit: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
