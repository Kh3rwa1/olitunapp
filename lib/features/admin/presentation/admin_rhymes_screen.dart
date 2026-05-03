import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import '../../../shared/providers/providers.dart';
import '../../rhymes/domain/rhyme_model.dart';
import 'widgets/admin_upload_field.dart';

class AdminRhymesScreen extends ConsumerStatefulWidget {
  const AdminRhymesScreen({super.key});

  @override
  ConsumerState<AdminRhymesScreen> createState() => _AdminRhymesScreenState();
}

class _AdminRhymesScreenState extends ConsumerState<AdminRhymesScreen> {
  @override
  Widget build(BuildContext context) {
    final rhymesAsync = ref.watch(rhymesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: rhymesAsync.when(
        data: (rhymes) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark, rhymes.length),
            Expanded(
              child: rhymes.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildRhymesList(rhymes, isDark),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRhymeDialog(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Rhyme',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.all(AdminTokens.space7),
      child: AdminPageHeader(
        title: 'Rhymes & Stories',
        subtitle: 'Manage kid-friendly content ($count items)',
        eyebrow: 'CONTENT · RHYMES',
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.go('/admin/rhymes/categories'),
            icon: const Icon(Icons.grid_view_rounded, size: 16),
            label: const Text('Manage Categories'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTokens.accent,
              side: BorderSide(color: AdminTokens.accentBorder(isDark)),
              backgroundColor: AdminTokens.accentSoft(isDark),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: Icons.music_note_rounded,
      title: 'No rhymes yet',
      message: 'Add your first rhyme or story to give learners something to sing along with.',
      actionLabel: 'Add Rhyme',
      onAction: () => _showRhymeDialog(context, null),
    );
  }

  Widget _buildRhymesList(List<RhymeModel> rhymes, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: rhymes.length,
      itemBuilder: (context, index) {
        final rhyme = rhymes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForCategory(rhyme.category),
                color: AppColors.primary,
              ),
            ),
            title: Text(
              rhyme.titleLatin,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rhyme.titleOlChiki, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (rhyme.category != null)
                      _buildChip(rhyme.category!, AppColors.primary),
                    if (rhyme.subcategory != null)
                      _buildChip(rhyme.subcategory!, AppColors.duoBlue),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _showRhymeDialog(context, rhyme),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => _confirmDelete(rhyme),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'animal':
        return Icons.pets_rounded;
      case 'nature':
        return Icons.wb_sunny_rounded;
      case 'moral':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }

  void _showRhymeDialog(BuildContext context, RhymeModel? rhyme) {
    final titleLatinController = TextEditingController(text: rhyme?.titleLatin);
    final titleOlChikiController = TextEditingController(
      text: rhyme?.titleOlChiki,
    );
    final contentLatinController = TextEditingController(
      text: rhyme?.contentLatin,
    );
    final contentOlChikiController = TextEditingController(
      text: rhyme?.contentOlChiki,
    );
    final audioController = TextEditingController(text: rhyme?.audioUrl);
    final thumbController = TextEditingController(text: rhyme?.thumbnailUrl);

    // Load categories and subcategories dynamically
    final categories = ref.read(rhymeCategoriesProvider).value ?? [];
    final allSubcategories = ref.read(rhymeSubcategoriesProvider).value ?? [];

    String selectedCategory =
        rhyme?.category ??
        (categories.isNotEmpty ? categories.first.nameLatin : 'General');
    String? selectedSubcategory = rhyme?.subcategory;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter subcategories by selected category
          final matchingCat = categories
              .where((c) => c.nameLatin == selectedCategory)
              .toList();
          final catId = matchingCat.isNotEmpty ? matchingCat.first.id : '';
          final filteredSubcats = allSubcategories
              .where((s) => s.categoryId == catId)
              .toList();

          // Validate selectedSubcategory
          final validSubcatNames = filteredSubcats
              .map((s) => s.nameLatin)
              .toList();
          if (selectedSubcategory != null &&
              !validSubcatNames.contains(selectedSubcategory)) {
            selectedSubcategory = filteredSubcats.isNotEmpty
                ? filteredSubcats.first.nameLatin
                : null;
          }

          return AlertDialog(
            title: Text(rhyme == null ? 'Add Rhyme' : 'Edit Rhyme'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleLatinController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Latin)',
                      ),
                    ),
                    TextField(
                      controller: titleOlChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Ol Chiki)',
                      ),
                    ),
                    TextField(
                      controller: contentLatinController,
                      decoration: const InputDecoration(
                        labelText: 'Content (Latin)',
                      ),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: contentOlChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Content (Ol Chiki)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    AdminUploadField(
                      controller: audioController,
                      label: 'Audio',
                      icon: Icons.audiotrack_rounded,
                      isDark: isDark,
                      folder: 'rhymes-audio',
                      uploadType: AdminUploadType.audio,
                      dialogSetState: setDialogState,
                    ),
                    const SizedBox(height: 16),
                    AdminUploadField(
                      controller: thumbController,
                      label: 'Thumbnail',
                      icon: Icons.image_rounded,
                      isDark: isDark,
                      folder: 'rhymes-images',
                      uploadType: AdminUploadType.lottieOrWebm,
                      dialogSetState: setDialogState,
                    ),
                    const SizedBox(height: 8),
                    // Category dropdown (dynamic)
                    DropdownButtonFormField<String>(
                      initialValue:
                          categories.any((c) => c.nameLatin == selectedCategory)
                          ? selectedCategory
                          : (categories.isNotEmpty
                                ? categories.first.nameLatin
                                : null),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.nameLatin,
                              child: Text(c.nameLatin),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val!;
                          selectedSubcategory = null; // reset subcategory
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    // Subcategory dropdown (cascading)
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubcategory,
                      items: filteredSubcats
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.nameLatin,
                              child: Text(s.nameLatin),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedSubcategory = val;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newItem = RhymeModel(
                    id: rhyme?.id ?? const Uuid().v4(),
                    titleLatin: titleLatinController.text,
                    titleOlChiki: titleOlChikiController.text,
                    contentLatin: contentLatinController.text,
                    contentOlChiki: contentOlChikiController.text,
                    audioUrl: audioController.text,
                    thumbnailUrl: thumbController.text,
                    category: selectedCategory,
                    subcategory: selectedSubcategory,
                  );

                  if (rhyme == null) {
                    ref.read(rhymesProvider.notifier).addRhyme(newItem);
                  } else {
                    ref.read(rhymesProvider.notifier).updateRhyme(newItem);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(RhymeModel rhyme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rhyme?'),
        content: Text('Are you sure you want to delete "${rhyme.titleLatin}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(rhymesProvider.notifier).deleteRhyme(rhyme.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
