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
  final ScrollController _sentencesScrollController = ScrollController();

  @override
  void dispose() {
    _sentencesScrollController.dispose();
    super.dispose();
  }

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
      body: Scrollbar(
        controller: _sentencesScrollController,
        thumbVisibility: true,
        child: CustomScrollView(
          controller: _sentencesScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                child: _buildHeader(context, isDark, isWideScreen),
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
            ),
            // Category filter
            SliverToBoxAdapter(
              child: Padding(
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
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Sentences List or States
            sentencesAsync.when(
              data: (sentences) {
                final filtered = _selectedCategory == null
                    ? sentences
                    : _filterSentences(sentences, subcategoryLessons);
                final selectedLesson = _selectedLesson(subcategoryLessons);
                if (filtered.isEmpty) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWideScreen ? 32 : 20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _emptyState(context, isDark, selectedLesson),
                    ),
                  );
                }
                return _buildSliverSentencesList(
                  filtered,
                  isDark,
                  isWideScreen,
                );
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
                      'Error loading sentences: $error',
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

  Widget _emptyState(
    BuildContext context,
    bool isDark,
    LessonEntity? selectedLesson,
  ) {
    if (selectedLesson != null && selectedLesson.blocks.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: AdminLessonBlocksNeedEditingState(
          title: 'Lesson blocks need review',
          message:
              '"${selectedLesson.titleLatin}" has ${selectedLesson.blocks.length} lesson blocks, but none of them contain enough text to create Sentence rows automatically. Open the content editor to fix or convert those blocks.',
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
        icon: Icons.format_quote_rounded,
        title: 'No sentences yet',
        message: _selectedCategory == null
            ? 'Add sentences for conversational practice.'
            : 'This subcategory has no saved Sentence records or editable lesson blocks yet.',
        actionLabel: 'Add Sentence',
        onAction: () => SentenceFormSheet.show(context, ref, null),
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

  Widget _buildSliverSentencesList(
    List<SentenceModel> sentences,
    bool isDark,
    bool isWideScreen,
  ) {
    final hasLessonBlockRows = sentences.any(_isLessonBlockSentence);
    final itemCount = sentences.length + (hasLessonBlockRows ? 1 : 0);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        120,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (hasLessonBlockRows && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AdminLessonBlockInfoBanner(
                title: 'Lesson-block drafts',
                message:
                    'This subcategory stores some content only as lesson blocks. Edit a draft to save it as a reusable Sentence record, or use the lesson content editor to change the original block.',
                isDark: isDark,
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06),
            );
          }

          final sentenceIndex = hasLessonBlockRows ? index - 1 : index;
          final sentence = sentences[sentenceIndex];
          final isLessonBlock = _isLessonBlockSentence(sentence);
          return SentenceCard(
            sentence: sentence,
            isDark: isDark,
            canDelete: !isLessonBlock,
            sourceLabel: isLessonBlock ? 'Lesson block draft' : null,
            sourceTooltip: isLessonBlock
                ? 'This row comes from a lesson content block. Editing it saves a new Sentence record.'
                : null,
            onEdit: () => SentenceFormSheet.show(context, ref, sentence),
            onDelete: () => _confirmDelete(context, sentence),
          ).animate().fadeIn(delay: (sentenceIndex * 50).ms).slideY(begin: 0.1);
        }, childCount: itemCount),
      ),
    );
  }

  bool _isLessonBlockSentence(SentenceModel sentence) =>
      sentence.id.startsWith('lesson_block_sentence_');

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
      try {
        await ref.read(sentencesProvider.notifier).delete(sentence.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete sentence: $e'),
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
      return _filterSentencesByCategory(sentences, selectedKey);
    }

    final exact =
        sentences
            .where(
              (sentence) =>
                  sentence.isActive &&
                  _lessonMatchesSentence(
                    lesson,
                    sentence.sentenceOlChiki,
                    sentence.sentenceLatin,
                    sentence.meaning,
                  ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    if (exact.isNotEmpty) {
      return _mergeSavedSentencesWithLessonBlocks(exact, lesson);
    }

    final categoryMatches = _filterSentencesByCategory(sentences, selectedKey);
    if (categoryMatches.isNotEmpty) {
      return _mergeSavedSentencesWithLessonBlocks(categoryMatches, lesson);
    }

    return _sentencesFromLessonBlocks(lesson);
  }

  List<SentenceModel> _mergeSavedSentencesWithLessonBlocks(
    List<SentenceModel> savedSentences,
    LessonEntity lesson,
  ) {
    final drafts = _sentencesFromLessonBlocks(lesson).where(
      (draft) =>
          !savedSentences.any((saved) => _sameSentenceRecord(saved, draft)),
    );
    return [...savedSentences, ...drafts];
  }

  bool _sameSentenceRecord(SentenceModel saved, SentenceModel draft) {
    final savedOlChiki = _normalizeKey(saved.sentenceOlChiki);
    final draftOlChiki = _normalizeKey(draft.sentenceOlChiki);
    if (savedOlChiki.isNotEmpty && savedOlChiki == draftOlChiki) return true;

    final savedLatin = _normalizeKey(saved.sentenceLatin);
    final draftLatin = _normalizeKey(draft.sentenceLatin);
    if (savedLatin.isNotEmpty && savedLatin == draftLatin) return true;

    final savedMeaning = _normalizeKey(saved.meaning);
    final draftMeaning = _normalizeKey(draft.meaning);
    return savedMeaning.isNotEmpty && savedMeaning == draftMeaning;
  }

  List<SentenceModel> _filterSentencesByCategory(
    List<SentenceModel> sentences,
    String key,
  ) {
    final aliases = _categoryAliases(key);
    return sentences
        .where(
          (sentence) =>
              aliases.contains(_normalizeKey(sentence.category ?? '')),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<SentenceModel> _sentencesFromLessonBlocks(LessonEntity lesson) {
    final category = lesson.titleLatin.trim();
    return [
      for (final row in adminTextRowsFromLessonBlocks(lesson))
        SentenceModel(
          id: 'lesson_block_sentence_${lesson.id}_${row.index}',
          sentenceOlChiki: row.olChiki,
          sentenceLatin: row.latin,
          meaning: row.meaning,
          category: category,
          imageUrl: row.imageUrl,
          audioUrl: row.audioUrl,
          animationUrl: row.animationUrl,
          order: row.index,
        ),
    ];
  }

  bool _lessonMatchesSentence(
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
    if (words.contains('basic')) aliases.add('basics');
    if (words.contains('daily') || words.contains('dialogues')) {
      aliases.add('conversations');
    }
    if (words.contains('greetings') || words.contains('politeness')) {
      aliases.add('polite');
    }
    if (words.contains('time') || words.contains('weather')) {
      aliases.add('time_weather');
    }
    if (words.contains('village') || words.contains('social')) {
      aliases.add('social');
    }
    if (words.contains('traditional') || words.contains('ecology')) {
      aliases.add('ecology');
    }
    if (words.contains('modern') || words.contains('conversational')) {
      aliases.add('modern');
    }
    if (words.contains('proverbs') || words.contains('wisdom')) {
      aliases.add('proverbs');
    }
    if (words.contains('cultural')) {
      aliases.add('culture');
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
      AdminContentKind.sentences,
    );
    final lesson = LessonEntity(
      id: id,
      categoryId: contentCategory.id,
      titleLatin: 'New Sentence Subcategory',
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
          'Delete "${lesson.titleLatin}" and its lesson content blocks? Individual sentence records are not deleted.',
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
