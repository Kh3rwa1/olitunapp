import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: AdminTokens.base(isDark)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),
                // Category filter chips
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: wordsAsync.when(
                    data: (words) {
                      final categories = words
                          .where((w) => w.category != null && w.category!.isNotEmpty)
                          .map((w) => w.category!)
                          .toSet()
                          .toList()
                        ..sort();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AdminFilterChip(
                              label: 'All Words',
                              selected: _selectedCategory == null,
                              onTap: () => setState(() => _selectedCategory = null),
                            ),
                            ...categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: AdminFilterChip(
                                  label: cat,
                                  selected: _selectedCategory == cat,
                                  onTap: () =>
                                      setState(() => _selectedCategory = cat),
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
                          : words.where((w) => w.category == _selectedCategory).toList();
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
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
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
}
