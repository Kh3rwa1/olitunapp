import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/appwrite_query_builders.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../data/bakhed_repository.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_empty_state.dart';
import '../../domain/content_badge_resolver.dart';
import '../widgets/content_type_badge.dart';
import '../../../../shared/widgets/cover_thumbnail.dart';
part 'bakhed_hub_sections.dart';

class BakhedHubScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  const BakhedHubScreen({super.key, this.categoryId});

  @override
  ConsumerState<BakhedHubScreen> createState() => _BakhedHubScreenState();
}

class _BakhedHubScreenState extends ConsumerState<BakhedHubScreen> {
  String _searchQuery = '';
  String? _selectedCategoryName;
  String _publishFilter = 'All'; // 'All', 'Published', 'Draft'
  bool _onlyHasAudio = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _selectedCategoryName = widget.categoryId == 'cat_sohrai'
          ? 'Sohrai'
          : widget.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listAsync = ref.watch(contentListProvider((ContentKind.rhyme, null)));
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);

    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AdminPageHeader(
                title: 'Rhymes & Stories (Bakhed)',
                eyebrow: 'CMS · RHYMES',
                subtitle:
                    'Manage kids play-along audio rhymes, lyrics timelines, vocabulary, and cultural notes.',
                actions: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to the editor with a fresh unique ID
                      final newId = DbId.unique();
                      context.go('/admin/bakhed/editor/$newId');
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'New Rhyme',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Filters Row
              Card(
                color: AdminTokens.raised(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  side: BorderSide(color: AdminTokens.border(isDark)),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by title...',
                            hintStyle: TextStyle(
                              color: AdminTokens.textMuted(isDark),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AdminTokens.textTertiary(isDark),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AdminTokens.radiusSm,
                              ),
                              borderSide: BorderSide(
                                color: AdminTokens.border(isDark),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AdminTokens.radiusSm,
                              ),
                              borderSide: BorderSide(
                                color: AdminTokens.border(isDark),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Category selector
                      categoriesAsync.when(
                        data: (categories) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AdminTokens.radiusSm,
                              ),
                              border: Border.all(
                                color: AdminTokens.border(isDark),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedCategoryName,
                                hint: Text(
                                  'All Categories',
                                  style: TextStyle(
                                    color: AdminTokens.textSecondary(isDark),
                                  ),
                                ),
                                dropdownColor: AdminTokens.overlay(isDark),
                                items: [
                                  DropdownMenuItem<String?>(
                                    child: Text(
                                      'All Categories',
                                      style: TextStyle(
                                        color: AdminTokens.textPrimary(isDark),
                                      ),
                                    ),
                                  ),
                                  ...categories.map(
                                    (c) => DropdownMenuItem<String?>(
                                      value: c.nameLatin,
                                      child: Text(
                                        c.nameLatin,
                                        style: TextStyle(
                                          color: AdminTokens.textPrimary(
                                            isDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryName = val),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          width: 150,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, _) => const SizedBox(),
                      ),
                      const SizedBox(width: 16),

                      // Publish status selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _publishFilter,
                            dropdownColor: AdminTokens.overlay(isDark),
                            items: ['All', 'Published', 'Draft'].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  '$status Status',
                                  style: TextStyle(
                                    color: AdminTokens.textPrimary(isDark),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _publishFilter = val ?? 'All'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Has Audio switch
                      Row(
                        children: [
                          Switch(
                            value: _onlyHasAudio,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) =>
                                setState(() => _onlyHasAudio = val),
                          ),
                          const SizedBox(width: 8),
                          Text('Has Audio', style: AdminTokens.body(isDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rhymes List Grid
              Expanded(
                child: listAsync.when(
                  data: (items) {
                    // Filter items
                    final filtered = items.where((item) {
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        final matchesTitle =
                            item.title.toLowerCase().contains(q) ||
                            (item.titleOlChiki?.toLowerCase().contains(q) ??
                                false);
                        if (!matchesTitle) return false;
                      }

                      if (_selectedCategoryName != null &&
                          item.category != _selectedCategoryName) {
                        return false;
                      }

                      if (_publishFilter == 'Published' && !item.isPublished) {
                        return false;
                      }
                      if (_publishFilter == 'Draft' && item.isPublished) {
                        return false;
                      }

                      if (_onlyHasAudio &&
                          (item.effectiveAudioUrl == null ||
                              item.effectiveAudioUrl!.isEmpty)) {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const AdminEmptyState(
                        title: 'No Rhymes Found',
                        message:
                            'Try adjusting your search queries or filter states.',
                        icon: Icons.music_off_rounded,
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final hasAudio =
                            item.effectiveAudioUrl != null &&
                            item.effectiveAudioUrl!.isNotEmpty;

                        // Find category name
                        String categoryName = item.category ?? '';
                        if (categoryName.isEmpty) {
                          categoriesAsync.whenData((cats) {
                            final match = cats
                                .where((c) => c.id == item.categoryId)
                                .toList();
                            if (match.isNotEmpty) {
                              categoryName = match.first.nameLatin;
                            }
                          });
                        }
                        if (categoryName.isEmpty) {
                          categoryName = item.categoryId.isNotEmpty
                              ? item.categoryId
                              : 'Unknown Category';
                        }

                        return _buildRhymeCard(
                          context,
                          ref,
                          isDark,
                          item,
                          categoryName,
                          hasAudio,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => AdminEmptyState(
                    title: 'Error Loading Rhymes',
                    message: err.toString(),
                    icon: Icons.error_outline_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
