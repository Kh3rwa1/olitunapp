import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/content_form.dart';

/// A unified, highly-polished content administration screen.
/// Parameterized by [ContentKind] to manage Letters, Numbers, Words, Sentences, Lessons, and Rhymes.
class AdminContentListScreen extends ConsumerStatefulWidget {
  final ContentKind kind;
  final String? categoryId;
  const AdminContentListScreen({
    super.key,
    required this.kind,
    this.categoryId,
  });

  @override
  ConsumerState<AdminContentListScreen> createState() =>
      _AdminContentListScreenState();
}

class _AdminContentListScreenState
    extends ConsumerState<AdminContentListScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _publishFilter = 'All'; // 'All', 'Published', 'Draft'
  String _premiumFilter = 'All'; // 'All', 'Premium', 'Free'

  Set<String> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String? _lastRouteCategoryId;

  @override
  void didUpdateWidget(covariant AdminContentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _debounce?.cancel();
      setState(() {
        _searchQuery = '';
        _selectedCategoryId = null;
        _lastRouteCategoryId = null;
        _publishFilter = 'All';
        _premiumFilter = 'All';
        _selectedIds.clear();
      });
    }
    // If the route's categoryId changed, update our selection
    if (oldWidget.categoryId != widget.categoryId &&
        widget.categoryId != null) {
      setState(() {
        _selectedCategoryId = widget.categoryId;
        _lastRouteCategoryId = widget.categoryId;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.kind) {
      case ContentKind.letter:
        return 'Ol Chiki Letters';
      case ContentKind.number:
        return 'Ol Chiki Numbers';
      case ContentKind.word:
        return 'Vocabulary Words';
      case ContentKind.sentence:
        return 'Sentences & Phrases';
      case ContentKind.lesson:
        return 'Subcategories';
      case ContentKind.rhyme:
        return 'Rhymes & Stories';
    }
  }

  String get _eyebrow {
    switch (widget.kind) {
      case ContentKind.letter:
        return 'CONTENT · LETTERS';
      case ContentKind.number:
        return 'CONTENT · NUMBERS';
      case ContentKind.word:
        return 'CONTENT · WORDS';
      case ContentKind.sentence:
        return 'CONTENT · SENTENCES';
      case ContentKind.lesson:
        return 'CONTENT · SUBCATEGORIES';
      case ContentKind.rhyme:
        return 'CONTENT · RHYMES';
    }
  }

  String get _subtitle {
    switch (widget.kind) {
      case ContentKind.letter:
        return 'Manage alphabet characters';
      case ContentKind.number:
        return 'Manage numerals and counting';
      case ContentKind.word:
        return 'Manage words and their meanings';
      case ContentKind.sentence:
        return 'Manage phrases and conversations';
      case ContentKind.lesson:
        return 'Create and manage subcategories';
      case ContentKind.rhyme:
        return 'Manage kid-friendly music and stories';
    }
  }

  IconData get _icon {
    switch (widget.kind) {
      case ContentKind.letter:
        return Icons.abc_rounded;
      case ContentKind.number:
        return Icons.pin_rounded;
      case ContentKind.word:
        return Icons.menu_book_rounded;
      case ContentKind.sentence:
        return Icons.format_quote_rounded;
      case ContentKind.lesson:
        return Icons.school_rounded;
      case ContentKind.rhyme:
        return Icons.music_note_rounded;
    }
  }

  void _invalidateAllProviders() {
    ref.invalidate(contentListProvider((widget.kind, null)));
    switch (widget.kind) {
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

  Future<void> _handleSeedData(BuildContext context) async {
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
        _invalidateAllProviders();
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

  Future<void> _exportToCsv(List<ContentItem> items) async {
    const csvHeader =
        'ID,Kind,Title,Title Ol Chiki,Ol Chiki,Subtitle,Category,Published,Premium,Order,Tags,Updated At\n';
    final csvRows = items
        .map((item) {
          return [
                item.id,
                item.kind.name,
                item.title,
                item.titleOlChiki ?? '',
                item.olChiki ?? '',
                item.subtitle ?? '',
                item.categoryId,
                item.isPublished.toString(),
                item.isPremium.toString(),
                item.order.toString(),
                item.tags.join('; '),
                item.updatedAt.toIso8601String(),
              ]
              .map((val) {
                final escaped = val.replaceAll('"', '""');
                return '"$escaped"';
              })
              .join(',');
        })
        .join('\n');

    final csvContent = csvHeader + csvRows;
    final filename = 'Olitun_${widget.kind.name}_Export.csv';

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvContent, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          title: 'Olitun $filename',
          subject: 'Olitun $_title Export',
          text: 'Olitun $_title Export',
          files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
          fileNameOverrides: [filename],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkPublish(
    List<ContentItem> filteredItems,
    bool publish,
  ) async {
    final selectedItems = filteredItems
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = ref.read(contentRepositoryProvider);
    int successCount = 0;

    // Concurrently process bulk updates in batches of 5 to maximize speed safely
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

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      setState(() {
        _selectedIds.clear();
      });
      _invalidateAllProviders();
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

  Future<void> _bulkDelete(List<ContentItem> filteredItems) async {
    final selectedItems = filteredItems
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    if (selectedItems.isEmpty) return;

    final confirm = await showAdminConfirmDialog(
      context: context,
      title: 'Bulk Delete',
      message:
          'Are you sure you want to delete ${selectedItems.length} items? This action cannot be undone.',
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = ref.read(contentRepositoryProvider);
    int successCount = 0;

    // Concurrently delete items in batches of 5 to maximize speed safely
    const batchSize = 5;
    for (int i = 0; i < selectedItems.length; i += batchSize) {
      final batch = selectedItems.skip(i).take(batchSize);
      await Future.wait(
        batch.map((item) async {
          final res = await repo.delete(widget.kind, item.id);
          res.fold((_) {}, (_) => successCount++);
        }),
      );
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      setState(() {
        _selectedIds.clear();
      });
      _invalidateAllProviders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $successCount items'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _editItem(BuildContext context, ContentItem item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = ref.read(contentRepositoryProvider);
    final res = await repo.get(widget.kind, item.id);

    if (context.mounted) {
      Navigator.pop(context); // close loader
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
        _showFormSheet(context, fullyLoadedItem);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, ContentItem item) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Content',
      message:
          'Are you sure you want to delete this "${item.title}" item? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      final repo = ref.read(contentRepositoryProvider);
      final res = await repo.delete(widget.kind, item.id);
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
          _invalidateAllProviders();
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

  void _showFormSheet(BuildContext context, ContentItem? initialItem) {
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
                      initialItem == null ? 'New $_title' : 'Edit $_title',
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
                    kind: widget.kind,
                    initial: initialItem,
                    categoryId: _selectedCategoryId,
                    onSubmit: (item) async {
                      final repo = ref.read(contentRepositoryProvider);
                      final res = await repo.upsert(item);

                      if (mounted) {
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
                            _invalidateAllProviders();
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

  List<ContentItem> _getFilteredItems(List<ContentItem> items) {
    var filtered = items;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(q) ||
            (item.titleOlChiki?.toLowerCase().contains(q) ?? false) ||
            (item.olChiki?.toLowerCase().contains(q) ?? false) ||
            (item.subtitle?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((item) => item.categoryId == _selectedCategoryId)
          .toList();
    }

    // Publish status filter
    if (_publishFilter == 'Published') {
      filtered = filtered.where((item) => item.isPublished).toList();
    } else if (_publishFilter == 'Draft') {
      filtered = filtered.where((item) => !item.isPublished).toList();
    }

    // Premium status filter
    if (_premiumFilter == 'Premium') {
      filtered = filtered.where((item) => item.isPremium).toList();
    } else if (_premiumFilter == 'Free') {
      filtered = filtered.where((item) => !item.isPremium).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final routeCategoryId = widget.categoryId;
    if (routeCategoryId != _lastRouteCategoryId) {
      _lastRouteCategoryId = routeCategoryId;
      // Use addPostFrameCallback to avoid mutating state during build
      if (routeCategoryId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCategoryId = routeCategoryId);
        });
      }
    }

    final listAsync = ref.watch(contentListProvider((widget.kind, null)));
    final categories = ref.watch(categoryNotifierProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    // Default to the first category if kind is lesson and categoryId is null/empty
    if (widget.kind == ContentKind.lesson &&
        (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) &&
        categories.isNotEmpty) {
      // Use a post-frame callback to avoid build-time side effects
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)) {
          setState(() => _selectedCategoryId = categories.first.id);
        }
      });
    }

    final headerActions = [
      OutlinedButton.icon(
        onPressed: () => _handleSeedData(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          ),
        ),
        icon: const Icon(Icons.cloud_download_rounded, size: 18),
        label: const Text(
          'Seed Default Data',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 8),
      listAsync.when(
        data: (items) => OutlinedButton.icon(
          onPressed: () => _exportToCsv(_getFilteredItems(items)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text(
            'CSV Export',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        loading: () => const SizedBox(),
        error: (err, st) => const SizedBox(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 32 : 20),
              child: Row(
                children: [
                  if (!isWideScreen) ...[
                    GestureDetector(
                      onTap: () => context.go('/admin'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminTokens.sunken(isDark),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AdminTokens.textPrimary(isDark),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AdminPageHeader(
                      title: _title,
                      subtitle: _subtitle,
                      eyebrow: _eyebrow,
                      actions: headerActions,
                    ),
                  ),
                ],
              ),
            ),

            // Search & Filter Controls
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 32 : 20),
              child: _buildFilterBar(isDark, categories),
            ),

            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: listAsync.when(
                data: (items) {
                  final filtered = _getFilteredItems(items);
                  if (filtered.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  final isGrid =
                      widget.kind == ContentKind.letter ||
                      widget.kind == ContentKind.number;
                  if (isGrid) {
                    return _buildGridView(filtered, isDark, isWideScreen);
                  }
                  return _buildListView(filtered, isDark, isWideScreen);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: AdminErrorState(
                    message: '$e',
                    onRetry: _invalidateAllProviders,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bulk Actions Bar
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : listAsync.when(
              data: (items) {
                final filtered = _getFilteredItems(items);
                final allSelected =
                    _selectedIds.length == filtered.length &&
                    filtered.isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Select all filtered items',
                          checked: allSelected,
                          child: Checkbox(
                            value: allSelected,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds = filtered
                                      .map((e) => e.id)
                                      .toSet();
                                } else {
                                  _selectedIds.clear();
                                }
                              });
                            },
                          ),
                        ),
                        Text(
                          '${_selectedIds.length} items selected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _bulkPublish(filtered, true),
                          icon: const Icon(Icons.publish_rounded, size: 16),
                          label: const Text('Publish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _bulkPublish(filtered, false),
                          icon: const Icon(Icons.unpublished_rounded, size: 16),
                          label: const Text('Draft'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _bulkDelete(filtered),
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            size: 16,
                          ),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (err, st) => const SizedBox(),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add $_title',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, List<dynamic> categories) {
    return Column(
      children: [
        // Search & Basic dropdowns
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _searchQuery = v;
                      _selectedIds
                          .clear(); // Auto-clear selection when filter changes
                    });
                  });
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search $_title...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white30 : Colors.black26,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Publish status dropdown
            _buildDropdown(
              value: _publishFilter,
              items: ['All', 'Published', 'Draft'],
              onChanged: (v) => setState(() {
                _publishFilter = v!;
                _selectedIds
                    .clear(); // Auto-clear selection when filter changes
              }),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            // Premium status dropdown
            _buildDropdown(
              value: _premiumFilter,
              items: ['All', 'Premium', 'Free'],
              onChanged: (v) => setState(() {
                _premiumFilter = v!;
                _selectedIds
                    .clear(); // Auto-clear selection when filter changes
              }),
              isDark: isDark,
            ),
          ],
        ),

        // Category chips row (if categories exist)
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Categories',
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() {
                    _selectedCategoryId = null;
                    _selectedIds
                        .clear(); // Auto-clear selection when filter changes
                  }),
                  isDark: isDark,
                ),
                ...categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFilterChip(
                      label: cat.titleLatin,
                      isSelected: _selectedCategoryId == cat.id,
                      onTap: () => setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedIds
                            .clear(); // Auto-clear selection when filter changes
                      }),
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Semantics(
      label: 'Dropdown filter for $value',
      button: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onChanged: onChanged,
            items: items.map((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val));
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      label: 'Category chip: $label',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: _icon,
      title: 'No items found',
      message:
          'No $_title match your filter or search query. Seed sample data or tap the "+" button to add one manually.',
      actionLabel: 'Add $_title',
      onAction: () => _showFormSheet(context, null),
    );
  }

  Widget _buildGridView(
    List<ContentItem> items,
    bool isDark,
    bool isWideScreen,
  ) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 6 : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(item.id);

        return InkWell(
              onTap: () => _editItem(context, item),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              child: AnimatedContainer(
                duration: 200.ms,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AdminTokens.raised(isDark),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AdminTokens.border(isDark),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: AdminTokens.raisedShadow(isDark),
                ),
                child: Stack(
                  children: [
                    // Checkbox for bulk actions
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Semantics(
                        label: 'Select ${item.title}',
                        checked: isSelected,
                        child: Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(item.id);
                              } else {
                                _selectedIds.remove(item.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // Status Dots
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          if (item.isPremium)
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.isPublished
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Core content: character or numeral
                    Align(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          (() {
                            final glyphText =
                                item.olChiki ?? item.titleOlChiki ?? item.title;
                            final isShort = glyphText.length <= 3;
                            return Text(
                              glyphText,
                              style: TextStyle(
                                fontFamily: 'OlChiki',
                                fontSize: isShort ? 32 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          })(),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete Button at bottom
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (index * 40).ms)
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildListView(
    List<ContentItem> items,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(item.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : AdminTokens.raised(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AdminTokens.border(isDark),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: AdminTokens.raisedShadow(isDark),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Select ${item.title}',
                  checked: isSelected,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(item.id);
                        } else {
                          _selectedIds.remove(item.id);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AdminTokens.accentSoft(isDark),
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(color: AdminTokens.border(isDark)),
                  ),
                  child: item.heroMedia != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusMd,
                          ),
                          child: Image.network(
                            item.heroMedia!.url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(_icon, color: AdminTokens.accent),
                          ),
                        )
                      : Icon(_icon, color: AdminTokens.accent),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  item.title,
                  style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 16),
                ),
                if (item.titleOlChiki != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${item.titleOlChiki})',
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Published badge
                    _buildStatusChip(
                      label: item.isPublished ? 'Published' : 'Draft',
                      color: item.isPublished
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      isDark: isDark,
                    ),
                    // Premium badge
                    _buildStatusChip(
                      label: item.isPremium ? 'Premium' : 'Free',
                      color: item.isPremium ? Colors.amber : Colors.blue,
                      isDark: isDark,
                    ),
                    // Tags
                    ...item.tags.map((tag) => _buildChip('#$tag', isDark)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.kind == ContentKind.lesson) ...[
                  AdminIconAction(
                    icon: Icons.dashboard_customize_rounded,
                    tooltip: 'Edit content blocks',
                    onTap: () =>
                        context.go('/admin/lessons/content/${item.id}'),
                  ),
                  const SizedBox(width: 6),
                ],
                AdminIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit metadata',
                  onTap: () => _editItem(context, item),
                ),
                const SizedBox(width: 6),
                AdminIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  destructive: true,
                  onTap: () => _confirmDelete(context, item),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AdminTokens.accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
