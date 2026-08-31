import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/providers/providers.dart';

void showContentFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ContentKind kind,
  required String title,
  required String? selectedCategoryId,
  ContentItem? initialItem,
  required VoidCallback onSaved,
}) {
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    initialItem == null ? 'New $title' : 'Edit $title',
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
                  kind: kind,
                  initial: initialItem,
                  categoryId: selectedCategoryId,
                  onSubmit: (item) async {
                    final repo = ref.read(contentRepositoryProvider);
                    final res = await repo.upsert(item);

                    if (context.mounted) {
                      res.fold(
                        (failure) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save: ${failure.message}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        (_) {
                          onSaved();
                          Navigator.pop(context);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
