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

    final routeCategoryId = GoRouterState.of(
      context,
    ).uri.queryParameters['categoryId'];
    final contentCategory = routeCategoryId != null
        ? (categories.where((c) => c.id == routeCategoryId).firstOrNull ??
              findAdminContentCategory(
                categories,
                AdminContentKind.vocabulary,
              ) ??
              (categories.isNotEmpty ? categories.first : null))
        : findAdminContentCategory(categories, AdminContentKind.vocabulary);

    final subcategoryLessons = filterAdminContentLessons(
      lessons,
      contentCategory,
      AdminContentKind.vocabulary,
    );
    final selectedLesson = _selectedLesson(subcategoryLessons);
    final selectedLessonId = selectedLesson?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Scrollbar(
        controller: _wordsScrollController,
        thumbVisibility: true,
        child: CustomScrollView(
          controller: _wordsScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                child: _buildHeader(
                  context,
                  isDark,
                  isWideScreen,
                  contentCategory,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWideScreen ? 32 : 20,
                  0,
                  isWideScreen ? 32 : 20,
                  18,
                ),
                child: AdminContentSubcategories(
                  title:
                      '${contentCategory?.titleLatin ?? "Vocabulary"} Subcategories',
                  subtitle:
                      'These are the lesson groups shown inside ${contentCategory?.titleLatin ?? "Vocabulary"} on the mobile app.',
                  emptyTitle: 'No subcategories found',
                  emptyMessage:
                      'Seed default data or add a subcategory to make editable.',
                  lessons: subcategoryLessons,
                  isDark: isDark,
                  onAdd: () => _addSubcategory(context, contentCategory),
                  onSeed: () => _handleSeedData(context),
                  onEdit: (lesson) =>
                      LessonFormSheet.show(context, ref, lesson),
                  onDelete: (lesson) =>
                      _confirmDeleteSubcategory(context, lesson),
                  selectedLessonId: selectedLessonId,
                  onSelect: (lesson) {
                    setState(() {
                      if (_selectedCategory == lesson.titleLatin) {
                        _selectedCategory = null;
                      } else {
                        _selectedCategory = lesson.titleLatin;
                      }
                    });
                  },
                  showContentEditor: false,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Words List or States
            wordsAsync.when(
              data: (words) {
                final filtered = _selectedCategory == null
                    ? words
                    : _filterWords(words, subcategoryLessons);
                if (filtered.isEmpty) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWideScreen ? 32 : 20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _emptyState(
                        context,
                        isDark,
                        selectedLesson,
                        contentCategory,
                      ),
                    ),
                  );
                }
                return _buildSliverWordsList(filtered, isDark, isWideScreen);
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: SelectableText(
                      'Error loading words: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => WordFormSheet.show(
          context,
          ref,
          null,
          initialCategory: _selectedCategory ?? contentCategory?.titleLatin,
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Word',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    bool isWideScreen,
    CategoryEntity? contentCategory,
  ) {
    final actions = [
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
    ];

    final isCustom =
        contentCategory != null &&
        contentCategory.id != 'cat_vocab' &&
        contentCategory.id != 'cat_words' &&
        contentCategory.id != 'seed_words';

    final title = isCustom ? contentCategory.titleLatin : 'Vocabulary';
    final eyebrow = isCustom
        ? 'CONTENT · ${contentCategory.titleLatin.toUpperCase()}'
        : 'CONTENT · WORDS';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: AdminPageHeader(
            title: title,
            subtitle: 'Manage words and their meanings',
            eyebrow: eyebrow,
            actions: actions,
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
    CategoryEntity? contentCategory,
  ) {
    if (selectedLesson != null && selectedLesson.blocks.isNotEmpty) {
      return Padding(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: AdminEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No words yet',
        message: _selectedCategory == null
            ? 'Add vocabulary words to build the learning dictionary.'
            : 'This subcategory has no words yet. Tap "Add Word" below to create one, or tap the selected card above to clear the filter and show all words.',
        actionLabel: 'Add Word',
        onAction: () => WordFormSheet.show(
          context,
          ref,
          null,
          initialCategory: _selectedCategory ?? contentCategory?.titleLatin,
        ),
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

  Widget _buildSliverWordsList(
    List<WordModel> words,
    bool isDark,
    bool isWideScreen,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        120,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final word = words[index];
          final isLessonBlock = _isLessonBlockWord(word);
          return WordCard(
            word: word,
            isDark: isDark,
            canDelete: !isLessonBlock,
            onEdit: () => WordFormSheet.show(context, ref, word),
            onDelete: () => _confirmDelete(context, word),
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
        }, childCount: words.length),
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
        setState(() {
          _selectedCategory = lesson.titleLatin;
        });
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
