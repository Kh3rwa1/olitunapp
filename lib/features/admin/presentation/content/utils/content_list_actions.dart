import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/utils/csv_helper.dart';
import 'package:itun/features/admin/presentation/widgets/admin_form_widgets.dart';
import 'package:itun/shared/providers/providers.dart';
import '../widgets/content_form_sheet.dart';
import 'content_csv_exporter.dart';

class ContentListActions {
  static void invalidateAllProviders(WidgetRef ref, ContentKind kind) {
    ref.invalidate(contentListProvider((kind, null)));
    switch (kind) {
      case ContentKind.letter:
        ref.invalidate(lettersProvider);
        break;
      case ContentKind.number:
        ref.invalidate(numbersProvider);
        break;
      case ContentKind.word:
        ref.invalidate(wordsProvider);
        break;
      case ContentKind.sentence:
        ref.invalidate(sentencesProvider);
        break;
      case ContentKind.lesson:
        ref.invalidate(lessonNotifierProvider);
        break;
      case ContentKind.rhyme:
        ref.invalidate(rhymesProvider);
        break;
    }
  }

  static Future<void> exportToCsv({
    required BuildContext context,
    required ContentKind kind,
    required String title,
    required List<ContentItem> items,
  }) async {
    final csvContent = buildContentListCsv(kind, items);
    final filename = 'Olitun_${kind.name}_Export.csv';
    try {
      await saveAndShareCsv(
        csvContent: csvContent,
        filename: filename,
        shareSubject: 'Olitun $title Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> handleSeedData({
    required BuildContext context,
    required WidgetRef ref,
    required ContentKind kind,
  }) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Seed All Default Data',
      message:
          'This will populate all categories, letters, subcategories, numbers, and words into your database. Existing custom data is preserved and not overwritten.',
    );

    if (ok == true) {
      try {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeding default data to database...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        await seedAppContent(ref);

        if (!context.mounted) return;
        invalidateAllProviders(ref, kind);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Default data seeded successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to seed data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> bulkPublish({
    required BuildContext context,
    required WidgetRef ref,
    required ContentKind kind,
    required List<ContentItem> items,
    required Set<String> selectedIds,
    required bool publish,
    required VoidCallback onComplete,
  }) async {
    final selectedItems = items
        .where((e) => selectedIds.contains(e.id))
        .toList();
    if (selectedItems.isEmpty) return;

    BuildContext? loaderDialogContext;
    bool isDialogPopped = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loaderDialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    await Future.delayed(Duration.zero);

    final repo = ref.read(contentRepositoryProvider);
    int successCount = 0;

    try {
      const batchSize = 5;
      for (int i = 0; i < selectedItems.length; i += batchSize) {
        final batch = selectedItems.skip(i).take(batchSize);
        await Future.wait(
          batch.map((item) async {
            final updated = item.copyWith(
              isPublished: publish,
              updatedAt: DateTime.now(),
            );
            final res = await repo.upsert(updated);
            res.fold((_) {}, (_) => successCount++);
          }),
        );
      }
    } finally {
      if (loaderDialogContext != null &&
          loaderDialogContext!.mounted &&
          !isDialogPopped) {
        isDialogPopped = true;
        Navigator.of(loaderDialogContext!).pop();
      }
    }

    if (context.mounted) {
      onComplete();
      invalidateAllProviders(ref, kind);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully updated $successCount items to ${publish ? "Published" : "Draft"}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  static Future<void> bulkDelete({
    required BuildContext context,
    required WidgetRef ref,
    required ContentKind kind,
    required List<ContentItem> items,
    required Set<String> selectedIds,
    required VoidCallback onComplete,
  }) async {
    final selectedItems = items
        .where((e) => selectedIds.contains(e.id))
        .toList();
    if (selectedItems.isEmpty) return;

    final confirm = await showAdminConfirmDialog(
      context: context,
      title: 'Bulk Delete',
      message:
          'Are you sure you want to delete ${selectedItems.length} items? This action cannot be undone.',
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    BuildContext? loaderDialogContext;
    bool isDialogPopped = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loaderDialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    await Future.delayed(Duration.zero);

    final repo = ref.read(contentRepositoryProvider);
    int successCount = 0;

    try {
      const batchSize = 5;
      for (int i = 0; i < selectedItems.length; i += batchSize) {
        final batch = selectedItems.skip(i).take(batchSize);
        await Future.wait(
          batch.map((item) async {
            final res = await repo.delete(kind, item.id);
            res.fold((_) {}, (_) => successCount++);
          }),
        );
      }
    } finally {
      if (loaderDialogContext != null &&
          loaderDialogContext!.mounted &&
          !isDialogPopped) {
        isDialogPopped = true;
        Navigator.of(loaderDialogContext!).pop();
      }
    }

    if (context.mounted) {
      onComplete();
      invalidateAllProviders(ref, kind);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $successCount items'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  static Future<void> editItem({
    required BuildContext context,
    required WidgetRef ref,
    required ContentKind kind,
    required String title,
    required String? selectedCategoryId,
    required ContentItem item,
    required VoidCallback onSaved,
  }) async {
    BuildContext? loaderDialogContext;
    bool isDialogPopped = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loaderDialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    await Future.delayed(Duration.zero);

    final repo = ref.read(contentRepositoryProvider);

    try {
      final res = await repo.get(kind, item.id);

      if (loaderDialogContext != null &&
          loaderDialogContext!.mounted &&
          !isDialogPopped) {
        isDialogPopped = true;
        Navigator.of(loaderDialogContext!).pop();
      }

      res.fold(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load item: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (fullyLoadedItem) {
          showContentFormSheet(
            context: context,
            ref: ref,
            kind: kind,
            title: title,
            selectedCategoryId: selectedCategoryId,
            initialItem: fullyLoadedItem,
            onSaved: onSaved,
          );
        },
      );
    } finally {
      if (loaderDialogContext != null &&
          loaderDialogContext!.mounted &&
          !isDialogPopped) {
        isDialogPopped = true;
        Navigator.of(loaderDialogContext!).pop();
      }
    }
  }

  static Future<void> confirmDelete({
    required BuildContext context,
    required WidgetRef ref,
    required ContentKind kind,
    required ContentItem item,
  }) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Content',
      message:
          'Are you sure you want to delete this "${item.title}" item? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      final repo = ref.read(contentRepositoryProvider);
      final res = await repo.delete(kind, item.id);
      res.fold(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          invalidateAllProviders(ref, kind);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item deleted successfully'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
      );
    }
  }
}
