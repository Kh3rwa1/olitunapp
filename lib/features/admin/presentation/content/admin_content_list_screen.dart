import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_states.dart';
import 'utils/content_list_actions.dart';
import 'widgets/content_bulk_action_bar.dart';
import 'widgets/content_filter_bar.dart';
import 'widgets/content_form_sheet.dart';
import 'widgets/content_grid_section.dart';
import 'widgets/content_list_section.dart';

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
  String _publishFilter = 'All';
  String _premiumFilter = 'All';

  Set<String> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();
  String? _lastRouteCategoryId;

  bool get _supportsCategory =>
      widget.kind == ContentKind.word ||
      widget.kind == ContentKind.sentence ||
      widget.kind == ContentKind.lesson ||
      widget.kind == ContentKind.rhyme;
  bool get _supportsPublished => widget.kind != ContentKind.rhyme;
  bool get _supportsPremium =>
      widget.kind == ContentKind.lesson || widget.kind == ContentKind.rhyme;
  bool get _supportsTags => widget.kind == ContentKind.rhyme;

  @override
  void didUpdateWidget(covariant AdminContentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      setState(() {
        _searchQuery = '';
        _selectedCategoryId = null;
        _lastRouteCategoryId = null;
        _publishFilter = 'All';
        _premiumFilter = 'All';
        _selectedIds.clear();
      });
    }
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

  List<ContentItem> _getFilteredItems(List<ContentItem> items) {
    var filtered = items;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(q) ||
            (item.titleOlChiki?.toLowerCase().contains(q) ?? false) ||
            (item.olChiki?.toLowerCase().contains(q) ?? false) ||
            (item.subtitle?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_supportsCategory && _selectedCategoryId != null) {
      filtered = filtered
          .where((item) => item.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_supportsPublished && _publishFilter == 'Published') {
      filtered = filtered.where((item) => item.isPublished).toList();
    } else if (_supportsPublished && _publishFilter == 'Draft') {
      filtered = filtered.where((item) => !item.isPublished).toList();
    }

    if (_supportsPremium && _premiumFilter == 'Premium') {
      filtered = filtered.where((item) => item.isPremium).toList();
    } else if (_supportsPremium && _premiumFilter == 'Free') {
      filtered = filtered.where((item) => !item.isPremium).toList();
    }

    return filtered;
  }

  void _openFormSheet(ContentItem? item) {
    showContentFormSheet(
      context: context,
      ref: ref,
      kind: widget.kind,
      title: _title,
      selectedCategoryId: _selectedCategoryId,
      initialItem: item,
      onSaved: () =>
          ContentListActions.invalidateAllProviders(ref, widget.kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeCategoryId = widget.categoryId;
    if (routeCategoryId != _lastRouteCategoryId) {
      _lastRouteCategoryId = routeCategoryId;
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

    if (widget.kind == ContentKind.lesson &&
        (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) &&
        categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)) {
          setState(() => _selectedCategoryId = categories.first.id);
        }
      });
    }

    final headerActions = [
      OutlinedButton.icon(
        onPressed: () => ContentListActions.handleSeedData(
          context: context,
          ref: ref,
          kind: widget.kind,
        ),
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
          onPressed: () => ContentListActions.exportToCsv(
            context: context,
            kind: widget.kind,
            title: _title,
            items: _getFilteredItems(items),
          ),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 32 : 20),
              child: ContentFilterBar(
                title: _title,
                isDark: isDark,
                supportsCategory: _supportsCategory,
                supportsPublished: _supportsPublished,
                supportsPremium: _supportsPremium,
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                publishFilter: _publishFilter,
                premiumFilter: _premiumFilter,
                onSearchChanged: (q) => setState(() {
                  _searchQuery = q;
                  _selectedIds.clear();
                }),
                onCategoryChanged: (catId) => setState(() {
                  _selectedCategoryId = catId;
                  _selectedIds.clear();
                }),
                onPublishFilterChanged: (pub) => setState(() {
                  _publishFilter = pub;
                  _selectedIds.clear();
                }),
                onPremiumFilterChanged: (prem) => setState(() {
                  _premiumFilter = prem;
                  _selectedIds.clear();
                }),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listAsync.when(
                data: (items) {
                  final filtered = _getFilteredItems(items);
                  if (filtered.isEmpty) {
                    return AdminEmptyState(
                      icon: _icon,
                      title: 'No items found',
                      message:
                          'No $_title match your filter or search query. Seed sample data or tap the "+" button to add one manually.',
                      actionLabel: 'Add $_title',
                      onAction: () => _openFormSheet(null),
                    );
                  }

                  final isGrid =
                      widget.kind == ContentKind.letter ||
                      widget.kind == ContentKind.number;
                  if (isGrid) {
                    return ContentGridSection(
                      scrollController: _scrollController,
                      items: filtered,
                      selectedIds: _selectedIds,
                      categories: categories,
                      defaultCategoryId:
                          _selectedCategoryId ?? widget.categoryId,
                      isDark: isDark,
                      isWideScreen: isWideScreen,
                      supportsPremium: _supportsPremium,
                      onEditItem: (item) => ContentListActions.editItem(
                        context: context,
                        ref: ref,
                        kind: widget.kind,
                        title: _title,
                        selectedCategoryId: _selectedCategoryId,
                        item: item,
                        onSaved: () =>
                            ContentListActions.invalidateAllProviders(
                              ref,
                              widget.kind,
                            ),
                      ),
                      onDeleteItem: (item) => ContentListActions.confirmDelete(
                        context: context,
                        ref: ref,
                        kind: widget.kind,
                        item: item,
                      ),
                      onToggleSelect: (id, selected) {
                        setState(() {
                          if (selected) {
                            _selectedIds.add(id);
                          } else {
                            _selectedIds.remove(id);
                          }
                        });
                      },
                    );
                  }

                  return ContentListSection(
                    scrollController: _scrollController,
                    items: filtered,
                    selectedIds: _selectedIds,
                    categories: categories,
                    defaultCategoryId: _selectedCategoryId ?? widget.categoryId,
                    isDark: isDark,
                    isWideScreen: isWideScreen,
                    supportsPublished: _supportsPublished,
                    supportsPremium: _supportsPremium,
                    supportsTags: _supportsTags,
                    icon: _icon,
                    onEditItem: (item) => ContentListActions.editItem(
                      context: context,
                      ref: ref,
                      kind: widget.kind,
                      title: _title,
                      selectedCategoryId: _selectedCategoryId,
                      item: item,
                      onSaved: () => ContentListActions.invalidateAllProviders(
                        ref,
                        widget.kind,
                      ),
                    ),
                    onDeleteItem: (item) => ContentListActions.confirmDelete(
                      context: context,
                      ref: ref,
                      kind: widget.kind,
                      item: item,
                    ),
                    onEditBlocks: widget.kind == ContentKind.lesson
                        ? (item) =>
                              context.go('/admin/lessons/content/${item.id}')
                        : null,
                    onToggleSelect: (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: AdminErrorState(
                    message: '$e',
                    onRetry: () => ContentListActions.invalidateAllProviders(
                      ref,
                      widget.kind,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : listAsync.when(
              data: (items) {
                final filtered = _getFilteredItems(items);
                final allSelected =
                    _selectedIds.length == filtered.length &&
                    filtered.isNotEmpty;
                return ContentBulkActionBar(
                  isDark: isDark,
                  selectedCount: _selectedIds.length,
                  allSelected: allSelected,
                  supportsPublished: _supportsPublished,
                  onToggleSelectAll: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds = filtered.map((e) => e.id).toSet();
                      } else {
                        _selectedIds.clear();
                      }
                    });
                  },
                  onBulkPublish: () => ContentListActions.bulkPublish(
                    context: context,
                    ref: ref,
                    kind: widget.kind,
                    items: filtered,
                    selectedIds: _selectedIds,
                    publish: true,
                    onComplete: () => setState(() => _selectedIds.clear()),
                  ),
                  onBulkDraft: () => ContentListActions.bulkPublish(
                    context: context,
                    ref: ref,
                    kind: widget.kind,
                    items: filtered,
                    selectedIds: _selectedIds,
                    publish: false,
                    onComplete: () => setState(() => _selectedIds.clear()),
                  ),
                  onBulkDelete: () => ContentListActions.bulkDelete(
                    context: context,
                    ref: ref,
                    kind: widget.kind,
                    items: filtered,
                    selectedIds: _selectedIds,
                    onComplete: () => setState(() => _selectedIds.clear()),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (err, st) => const SizedBox(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormSheet(null),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.elevatedButtonFg,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add $_title',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
