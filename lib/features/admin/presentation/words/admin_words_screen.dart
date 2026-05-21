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
import '../widgets/admin_lesson_block_info_banner.dart';
import '../widgets/admin_lesson_block_text.dart';
import 'widgets/word_form_sheet.dart';
import 'widgets/word_card.dart';

class AdminWordsScreen extends ConsumerStatefulWidget {
  const AdminWordsScreen({super.key});

  @override
  ConsumerState<AdminWordsScreen> createState() => _AdminWordsScreenState();
}

class _AdminWordsScreenState extends ConsumerState<AdminWordsScreen> {
  String? _selectedCategory;
  final ScrollController _wordsScrollController = ScrollController();

  @override
  void dispose() {
    _wordsScrollController.dispose();
    super.dispose();
  }

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
                      final selectedLesson = _selectedLesson(
                        subcategoryLessons,
                      );
                      return filtered.isEmpty
                          ? _emptyState(context, isDark, selectedLesson)
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

  Widget _emptyState(
    BuildContext context,
    bool isDark,
    LessonEntity? selectedLesson,
  ) {
    if (selectedLesson != null && selectedLesson.blocks.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: AdminLessonBlocksNeedEditingState(
          title: 'Lesson blocks need review',
          message:
              '"${selectedLesson.titleLatin}" has ${selectedLesson.blocks.length} lesson blocks, but none of them contain enough text to create Word rows automatically. Open the content editor to fix or convert those blocks.',
          actionLabel: 'Edit Lesson Content',
          isDark: isDark,
          onAction: () =>
              context.go('/admin/lessons/content/${selectedLesson.id}'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: AdminEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No words yet',
        message: _selectedCategory == null
            ? 'Add vocabulary words to build the learning dictionary.'
            : 'This subcategory has no saved Word records or editable lesson blocks yet.',
        actionLabel: 'Add Word',
        onAction: () => WordFormSheet.show(context, ref, null),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
    );
  }

  LessonEntity? _selectedLesson(List<LessonEntity> subcategoryLessons) {
    final selected = _selectedCategory;
    if (selected == null) return null;
    final selectedKey = _normalizeKey(selected);
    return subcategoryLessons
        .where((lesson) => _normalizeKey(lesson.titleLatin) == selectedKey)
        .firstOrNull;
  }

  Widget _buildWordsList(
    List<WordModel> words,
    bool isDark,
    bool isWideScreen,
  ) {
    final hasLessonBlockRows = words.any(_isLessonBlockWord);
    final itemCount = words.length + (hasLessonBlockRows ? 1 : 0);

    return Scrollbar(
      controller: _wordsScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _wordsScrollController,
        padding: EdgeInsets.fromLTRB(
          isWideScreen ? 32 : 20,
          0,
          isWideScreen ? 32 : 20,
          120,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (hasLessonBlockRows && index == 0) {
            return AdminLessonBlockInfoBanner(
              title: 'Lesson-block drafts',
              message:
                  'This subcategory stores some content only as lesson blocks. Edit a draft to save it as a reusable Word record, or use the lesson content editor to change the original block.',
              isDark: isDark,
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06);
          }

          final wordIndex = hasLessonBlockRows ? index - 1 : index;
          final word = words[wordIndex];
          final isLessonBlock = _isLessonBlockWord(word);
          return WordCard(
            word: word,
            isDark: isDark,
            canDelete: !isLessonBlock,
            sourceLabel: isLessonBlock ? 'Lesson block draft' : null,
            sourceTooltip: isLessonBlock
                ? 'This row comes from a lesson content block. Editing it saves a new Word record.'
                : null,
            onEdit: () => WordFormSheet.show(context, ref, word),
            onDelete: () => _confirmDelete(context, word),
          ).animate().fadeIn(delay: (wordIndex * 50).ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  bool _isLessonBlockWord(WordModel word) =>
      word.id.startsWith('lesson_block_word_');

  Future<void> _confirmDelete(BuildContext context, WordModel word) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Word',
      message:
          'Are you sure you want to delete "${word.wordLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(wordsProvider.notifier).deleteWord(word.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete word: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    if (exact.isNotEmpty) {
      return _mergeSavedWordsWithLessonBlocks(exact, lesson);
    }

    final categoryMatches = _filterWordsByCategory(words, selectedKey);
    if (categoryMatches.isNotEmpty) {
      return _mergeSavedWordsWithLessonBlocks(categoryMatches, lesson);
    }

    return _wordsFromLessonBlocks(lesson);
  }

  List<WordModel> _mergeSavedWordsWithLessonBlocks(
    List<WordModel> savedWords,
    LessonEntity lesson,
  ) {
    final drafts = _wordsFromLessonBlocks(lesson).where(
      (draft) => !savedWords.any((saved) => _sameWordRecord(saved, draft)),
    );
    return [...savedWords, ...drafts];
  }

  bool _sameWordRecord(WordModel saved, WordModel draft) {
    final savedOlChiki = _normalizeKey(saved.wordOlChiki);
    final draftOlChiki = _normalizeKey(draft.wordOlChiki);
    if (savedOlChiki.isNotEmpty && savedOlChiki == draftOlChiki) return true;

    final savedLatin = _normalizeKey(saved.wordLatin);
    final draftLatin = _normalizeKey(draft.wordLatin);
    if (savedLatin.isNotEmpty && savedLatin == draftLatin) return true;

    final savedMeaning = _normalizeKey(saved.meaning);
    final draftMeaning = _normalizeKey(draft.meaning);
    return savedMeaning.isNotEmpty && savedMeaning == draftMeaning;
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
    return [
      for (final row in adminTextRowsFromLessonBlocks(lesson))
        WordModel(
          id: 'lesson_block_word_${lesson.id}_${row.index}',
          wordOlChiki: row.olChiki,
          wordLatin: row.latin,
          meaning: row.meaning,
          category: category,
          imageUrl: row.imageUrl,
          audioUrl: row.audioUrl,
          animationUrl: row.animationUrl,
          order: row.index,
        ),
    ];
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
    for (final row in adminTextRowsFromLessonBlocks(lesson)) {
      final values = [
        _normalizeKey(row.olChiki),
        _normalizeKey(row.latin),
        _normalizeKey(row.meaning),
      ];
      for (final value in values.where((value) => value.isNotEmpty)) {
        yield value;
        for (final part in value.split(RegExp(r'\s+[–-]\s+'))) {
          final normalizedPart = _normalizeKey(part);
          if (normalizedPart.isNotEmpty) yield normalizedPart;
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
    try {
      await ref.read(lessonNotifierProvider.notifier).addLesson(lesson);
      if (context.mounted) {
        context.go('/admin/lessons/content/$id');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add subcategory: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      try {
        await ref.read(lessonNotifierProvider.notifier).deleteLesson(lesson.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subcategory: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
