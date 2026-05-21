import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart';
import '../lessons/widgets/lesson_form_sheet.dart';
import '../widgets/admin_content_subcategories.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_form_widgets.dart';
import 'widgets/sentence_form_sheet.dart';
import 'widgets/sentence_card.dart';

class AdminSentencesScreen extends ConsumerStatefulWidget {
  const AdminSentencesScreen({super.key});

  @override
  ConsumerState<AdminSentencesScreen> createState() =>
      _AdminSentencesScreenState();
}

class _AdminSentencesScreenState extends ConsumerState<AdminSentencesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final sentencesAsync = ref.watch(sentencesProvider);
    final categories = ref.watch(categoryNotifierProvider).value ?? [];
    final lessons = ref.watch(lessonNotifierProvider).value ?? [];
    final contentCategory = findAdminContentCategory(
      categories,
      AdminContentKind.sentences,
    );
    final subcategoryLessons = filterAdminContentLessons(
      lessons,
      contentCategory,
      AdminContentKind.sentences,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWideScreen ? 32 : 20,
                    0,
                    isWideScreen ? 32 : 20,
                    18,
                  ),
                  child: AdminContentSubcategories(
                    title: 'Sentence Subcategories',
                    subtitle:
                        'These are the lesson groups shown inside Sentences on the mobile app.',
                    emptyTitle: 'No sentence subcategories found',
                    emptyMessage:
                        'Seed default data or add a subcategory to make Sentences editable.',
                    lessons: subcategoryLessons,
                    isDark: isDark,
                    onAdd: () => _addSubcategory(context, contentCategory),
                    onSeed: () => _handleSeedData(context),
                    onEdit: (lesson) =>
                        LessonFormSheet.show(context, ref, lesson),
                    onDelete: (lesson) =>
                        _confirmDeleteSubcategory(context, lesson),
                  ),
                ),
                // Category filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: sentencesAsync.when(
                    data: (sentences) {
                      final filterLabels = _buildFilterLabels(
                        sentences.map((s) => s.category),
                        subcategoryLessons,
                      );
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AdminFilterChip(
                              label: 'All Sentences',
                              selected: _selectedCategory == null,
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                            ),
                            ...filterLabels.map(
                              (label) => Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: AdminFilterChip(
                                  label: label,
                                  selected: _selectedCategory == label,
                                  onTap: () =>
                                      setState(() => _selectedCategory = label),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 40),
                    error: (_, _) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: sentencesAsync.when(
                    data: (sentences) {
                      final filtered = _selectedCategory == null
                          ? _filterSentencesForLessons(
                              sentences,
                              subcategoryLessons,
                            )
                          : _filterSentences(sentences, subcategoryLessons);
                      return filtered.isEmpty
                          ? _emptyState(context, isDark)
                          : _buildSentencesList(filtered, isDark, isWideScreen);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: SelectableText(
                        'Error loading sentences: $error',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SentenceFormSheet.show(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Sentence',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Row(
      children: [
        if (!isWideScreen) ...[
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTokens.sunken(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
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
        const Expanded(
          child: AdminPageHeader(
            title: 'Sentences',
            subtitle: 'Manage phrases and conversations',
            eyebrow: 'CONTENT · SENTENCES',
          ),
        ),
        const SizedBox(width: 16),
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
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Future<void> _handleSeedData(BuildContext context) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Seed Default Data',
      message:
          'This will populate your app with rich sample categories, letters, lessons, and numbers. Existing custom data is preserved and not overwritten.',
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

  Widget _emptyState(BuildContext context, bool isDark) {
    return AdminEmptyState(
      icon: Icons.format_quote_rounded,
      title: 'No sentences yet',
      message: 'Add sentences for conversational practice.',
      actionLabel: 'Add Sentence',
      onAction: () => SentenceFormSheet.show(context, ref, null),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSentencesList(
    List<SentenceModel> sentences,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: sentences.length,
      itemBuilder: (context, index) {
        final sentence = sentences[index];
        return SentenceCard(
          sentence: sentence,
          isDark: isDark,
          onEdit: () => SentenceFormSheet.show(context, ref, sentence),
          onDelete: () => _confirmDelete(context, sentence),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SentenceModel sentence,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Sentence',
      message:
          'Are you sure you want to delete this sentence? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(sentencesProvider.notifier).delete(sentence.id);
    }
  }

  List<String> _buildFilterLabels(
    Iterable<String?> rowCategories,
    List<LessonEntity> subcategoryLessons,
  ) {
    final labels = <String>[];
    final seen = <String>{};

    void add(String? value) {
      final label = value?.trim();
      if (label == null || label.isEmpty) return;
      if (seen.add(label.toLowerCase())) labels.add(label);
    }

    for (final lesson in subcategoryLessons) {
      add(lesson.titleLatin);
    }

    if (labels.isEmpty) {
      final categories =
          rowCategories
              .where((value) => value != null && value.trim().isNotEmpty)
              .map((value) => value!.trim())
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      for (final category in categories) {
        add(category);
      }
    }

    return labels;
  }

  List<SentenceModel> _filterSentencesForLessons(
    List<SentenceModel> sentences,
    List<LessonEntity> subcategoryLessons,
  ) {
    if (subcategoryLessons.isEmpty) return sentences;
    final allowed = subcategoryLessons
        .expand(_normalizedTextBlockValues)
        .toSet();
    if (allowed.isEmpty) return const [];
    return sentences
        .where(
          (sentence) =>
              sentence.isActive &&
              allowed.contains(_normalizeKey(sentence.sentenceOlChiki)),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<SentenceModel> _filterSentences(
    List<SentenceModel> sentences,
    List<LessonEntity> subcategoryLessons,
  ) {
    final selected = _selectedCategory;
    if (selected == null) return sentences;
    final selectedKey = _normalizeKey(selected);

    final lesson = subcategoryLessons
        .where((lesson) => _normalizeKey(lesson.titleLatin) == selectedKey)
        .firstOrNull;
    if (lesson == null) {
      return sentences
          .where(
            (sentence) => _normalizeKey(sentence.category ?? '') == selectedKey,
          )
          .toList();
    }

    final blockTexts = _normalizedTextBlockValues(lesson).toSet();
    if (blockTexts.isEmpty) return const [];

    return sentences
        .where(
          (sentence) =>
              sentence.isActive &&
              blockTexts.contains(_normalizeKey(sentence.sentenceOlChiki)),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Iterable<String> _normalizedTextBlockValues(LessonEntity lesson) {
    return lesson.blocks
        .where((block) => block.type == 'text' && block.textOlChiki != null)
        .map((block) => _normalizeKey(block.textOlChiki!))
        .where((text) => text.isNotEmpty);
  }

  String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _addSubcategory(
    BuildContext context,
    CategoryEntity? contentCategory,
  ) async {
    if (contentCategory == null) {
      await _handleSeedData(context);
      return;
    }

    final id = const Uuid().v4();
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
    final existing = filterAdminContentLessons(
      lessons,
      contentCategory,
      AdminContentKind.sentences,
    );
    final lesson = LessonEntity(
      id: id,
      categoryId: contentCategory.id,
      titleLatin: 'New Sentence Subcategory',
      titleOlChiki: '',
      order: existing.length,
    );
    await ref.read(lessonNotifierProvider.notifier).addLesson(lesson);
    if (context.mounted) {
      context.go('/admin/lessons/content/$id');
    }
  }

  Future<void> _confirmDeleteSubcategory(
    BuildContext context,
    LessonEntity lesson,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Subcategory',
      message:
          'Delete "${lesson.titleLatin}" and its lesson content blocks? Individual sentence records are not deleted.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref.read(lessonNotifierProvider.notifier).deleteLesson(lesson.id);
    }
  }
}
