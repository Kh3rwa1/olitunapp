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
import 'widgets/word_form_sheet.dart';
import 'widgets/word_card.dart';

class AdminWordsScreen extends ConsumerStatefulWidget {
  const AdminWordsScreen({super.key});

  @override
  ConsumerState<AdminWordsScreen> createState() => _AdminWordsScreenState();
}

class _AdminWordsScreenState extends ConsumerState<AdminWordsScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    final categories = ref.watch(categoryNotifierProvider).value ?? [];
    final lessons = ref.watch(lessonNotifierProvider).value ?? [];
    final contentCategory = findAdminContentCategory(
      categories,
      AdminContentKind.vocabulary,
    );
    final subcategoryLessons = filterAdminContentLessons(
      lessons,
      contentCategory,
      AdminContentKind.vocabulary,
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
                    title: 'Vocabulary Subcategories',
                    subtitle:
                        'These are the lesson groups shown inside Vocabulary on the mobile app.',
                    emptyTitle: 'No vocabulary subcategories found',
                    emptyMessage:
                        'Seed default data or add a subcategory to make Vocabulary editable.',
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
                // Category filter chips
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: wordsAsync.when(
                    data: (words) {
                      final filterLabels = _buildFilterLabels(
                        words.map((w) => w.category),
                        subcategoryLessons,
                      );
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AdminFilterChip(
                              label: 'All Words',
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
                  child: wordsAsync.when(
                    data: (words) {
                      final filtered = _selectedCategory == null
                          ? words
                          : _filterWords(words, subcategoryLessons);
                      return filtered.isEmpty
                          ? _emptyState(context, isDark)
                          : _buildWordsList(filtered, isDark, isWideScreen);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: SelectableText(
                        'Error loading words: $error',
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
        onPressed: () => WordFormSheet.show(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Word',
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
            title: 'Vocabulary',
            subtitle: 'Manage words and their meanings',
            eyebrow: 'CONTENT · WORDS',
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
      icon: Icons.menu_book_rounded,
      title: 'No words yet',
      message: 'Add vocabulary words to build the learning dictionary.',
      actionLabel: 'Add Word',
      onAction: () => WordFormSheet.show(context, ref, null),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildWordsList(
    List<WordModel> words,
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
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return WordCard(
          word: word,
          isDark: isDark,
          onEdit: () => WordFormSheet.show(context, ref, word),
          onDelete: () => _confirmDelete(context, word),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WordModel word) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Word',
      message:
          'Are you sure you want to delete "${word.wordLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(wordsProvider.notifier).deleteWord(word.id);
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

  List<WordModel> _filterWords(
    List<WordModel> words,
    List<LessonEntity> subcategoryLessons,
  ) {
    final selected = _selectedCategory;
    if (selected == null) return words;
    final selectedKey = _normalizeKey(selected);

    final lesson = subcategoryLessons
        .where((lesson) => _normalizeKey(lesson.titleLatin) == selectedKey)
        .firstOrNull;
    if (lesson == null) {
      return _filterWordsByCategory(words, selectedKey);
    }

    final exact =
        words
            .where(
              (word) =>
                  word.isActive &&
                  _lessonMatchesWord(
                    lesson,
                    word.wordOlChiki,
                    word.wordLatin,
                    word.meaning,
                  ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    if (exact.isNotEmpty) return exact;

    final categoryMatches = _filterWordsByCategory(words, selectedKey);
    if (categoryMatches.isNotEmpty) return categoryMatches;

    return _wordsFromLessonBlocks(lesson);
  }

  List<WordModel> _filterWordsByCategory(List<WordModel> words, String key) {
    final aliases = _categoryAliases(key);
    return words
        .where((word) => aliases.contains(_normalizeKey(word.category ?? '')))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<WordModel> _wordsFromLessonBlocks(LessonEntity lesson) {
    final category = lesson.titleLatin.trim();
    final blocks = lesson.blocks
        .where((block) => block.type == 'text')
        .toList();
    return [
      for (var i = 0; i < blocks.length; i++)
        WordModel(
          id: 'lesson_block_word_${lesson.id}_$i',
          wordOlChiki: blocks[i].textOlChiki?.trim() ?? '',
          wordLatin: _latinPart(blocks[i].textLatin),
          meaning: _meaningPart(blocks[i].textLatin),
          category: category,
          order: i,
        ),
    ].where((word) => word.wordOlChiki.isNotEmpty).toList();
  }

  bool _lessonMatchesWord(
    LessonEntity lesson,
    String olChiki,
    String latin,
    String meaning,
  ) {
    final values = [
      _normalizeKey(olChiki),
      _normalizeKey(latin),
      _normalizeKey(meaning),
    ].where((value) => value.isNotEmpty).toList();
    return _normalizedTextBlockValues(lesson).any(
      (blockText) => values.any(
        (value) => blockText == value || blockText.contains(value),
      ),
    );
  }

  Iterable<String> _normalizedTextBlockValues(LessonEntity lesson) sync* {
    for (final block in lesson.blocks.where((block) => block.type == 'text')) {
      final olChiki = _normalizeKey(block.textOlChiki ?? '');
      if (olChiki.isNotEmpty) yield olChiki;
      final latin = _normalizeKey(block.textLatin ?? '');
      if (latin.isNotEmpty) {
        yield latin;
        for (final part in latin.split(RegExp(r'\s+[–-]\s+'))) {
          final value = _normalizeKey(part);
          if (value.isNotEmpty) yield value;
        }
      }
    }
  }

  Set<String> _categoryAliases(String key) {
    final aliases = <String>{key};
    final words = key.split(' ').toSet();
    if (words.contains('greetings')) aliases.add('greeting');
    if (words.contains('basics')) aliases.add('basic');
    if (words.contains('family')) aliases.add('family');
    if (words.contains('daily')) aliases.add('daily');
    if (words.contains('colors')) aliases.add('colors');
    if (words.contains('nature') || words.contains('animals')) {
      aliases.add('nature');
    }
    if (words.contains('months') ||
        words.contains('days') ||
        words.contains('seasons')) {
      aliases.add('time');
    }
    if (words.contains('trending') || words.contains('popular')) {
      aliases.add('trending');
    }
    if (words.contains('idioms') || words.contains('life')) {
      aliases.add('daily');
    }
    if (words.contains('proverbs') || words.contains('wisdom')) {
      aliases.add('proverbs');
    }
    if (words.contains('modern') || words.contains('conversational')) {
      aliases.add('modern');
    }
    if (words.contains('casual') || words.contains('slang')) {
      aliases.add('slang');
    }
    return aliases;
  }

  String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _latinPart(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    return text.split(RegExp(r'\s+[–-]\s+')).first.trim();
  }

  String _meaningPart(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    final parts = text.split(RegExp(r'\s+[–-]\s+'));
    return parts.length > 1 ? parts.sublist(1).join(' - ').trim() : text;
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
      AdminContentKind.vocabulary,
    );
    final lesson = LessonEntity(
      id: id,
      categoryId: contentCategory.id,
      titleLatin: 'New Vocabulary Subcategory',
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
          'Delete "${lesson.titleLatin}" and its lesson content blocks? Individual word records are not deleted.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref.read(lessonNotifierProvider.notifier).deleteLesson(lesson.id);
    }
  }
}
