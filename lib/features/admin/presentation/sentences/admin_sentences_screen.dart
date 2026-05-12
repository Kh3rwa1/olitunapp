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
                // Category filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: sentencesAsync.when(
                    data: (sentences) {
                      final categories = sentences
                          .where((s) => s.category != null && s.category!.isNotEmpty)
                          .map((s) => s.category!)
                          .toSet()
                          .toList()
                        ..sort();
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
                  child: sentencesAsync.when(
                    data: (sentences) {
                      final filtered = _selectedCategory == null
                          ? sentences
                          : sentences
                                .where((s) => s.category == _selectedCategory)
                                .toList();
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
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
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
}
