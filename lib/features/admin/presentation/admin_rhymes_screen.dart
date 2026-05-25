import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import '../../../shared/providers/providers.dart';
import '../../rhymes/domain/rhyme_model.dart';
import 'widgets/admin_form_widgets.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

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
        loading: () => const AdminLoadingState(label: 'Loading rhymes…'),
        error: (e, st) => AdminErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(rhymesProvider),
        ),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AdminEmptyState(
      icon: Icons.music_note_rounded,
      title: 'No rhymes yet',
      message:
          'Add your first rhyme or story to give learners something to sing along with.',
      actionLabel: 'Add Rhyme',
      onAction: () => _showRhymeDialog(context, null),
    );
  }

  Widget _buildRhymesList(List<RhymeModel> rhymes, bool isDark) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        0,
        isMobile ? 16 : 32,
        100,
      ),
      itemCount: rhymes.length,
      itemBuilder: (context, index) {
        final rhyme = rhymes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AdminTokens.raised(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusLg),
            border: Border.all(color: AdminTokens.border(isDark)),
            boxShadow: AdminTokens.raisedShadow(isDark),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AdminTokens.accentSoft(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                border: Border.all(color: AdminTokens.border(isDark)),
              ),
              child: Icon(
                _getIconForCategory(rhyme.category),
                color: AdminTokens.accent,
              ),
            ),
            title: Text(
              rhyme.titleLatin,
              style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rhyme.titleOlChiki, style: AdminTokens.label(isDark)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (rhyme.category != null)
                      _buildChip(rhyme.category!, isDark),
                    ...rhyme.tags.map((tag) => _buildChip('#$tag', isDark)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit',
                  onTap: () => _showRhymeDialog(context, rhyme),
                ),
                const SizedBox(width: 6),
                AdminIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  destructive: true,
                  onTap: () => _confirmDelete(rhyme),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AdminTokens.accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'sohrai':
        return Icons.agriculture_rounded;
      case 'baha':
        return Icons.local_florist_rounded;
      case 'mag\'more':
        return Icons.eco_rounded;
      case 'chhatyar':
        return Icons.child_friendly_rounded;
      case 'bapla':
        return Icons.favorite_rounded;
      case 'bhandan':
        return Icons.group_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  void _showRhymeDialog(BuildContext context, RhymeModel? rhyme) {
    ContentItem? initialItem;
    if (rhyme != null) {
      final blocks = <ContentBlock>[];
      if (rhyme.contentOlChiki.isNotEmpty) {
        blocks.add(
          TextBlock(
            id: 'content_ol_chiki',
            order: 0,
            markdown: rhyme.contentOlChiki,
          ),
        );
      }
      if (rhyme.contentLatin.isNotEmpty) {
        blocks.add(
          TextBlock(
            id: 'content_latin',
            order: 1,
            markdown: rhyme.contentLatin,
          ),
        );
      }
      if (rhyme.audioUrl != null && rhyme.audioUrl!.isNotEmpty) {
        blocks.add(
          AudioBlock(
            id: 'audio',
            order: 2,
            media: ContentMedia(
              url: rhyme.audioUrl!,
              fileId: '',
              kind: ContentMediaKind.audio,
            ),
          ),
        );
      }

      initialItem = ContentItem(
        id: rhyme.id,
        kind: ContentKind.rhyme,
        categoryId: rhyme.categoryId ?? '',
        title: rhyme.titleLatin,
        titleOlChiki: rhyme.titleOlChiki,
        heroMedia:
            (rhyme.thumbnailUrl != null && rhyme.thumbnailUrl!.isNotEmpty)
            ? ContentMedia(
                url: rhyme.thumbnailUrl!,
                fileId: '',
                kind: ContentMediaKind.image,
              )
            : null,
        blocks: blocks,
        tags: rhyme.tags,
        updatedAt: DateTime.now(),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rhyme == null ? 'New Rhyme' : 'Edit Rhyme',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ContentForm(
                    kind: ContentKind.rhyme,
                    initial: initialItem,
                    onSubmit: (item) async {
                      final repo = ref.read(contentRepositoryProvider);
                      final res = await repo.upsert(item);

                      if (mounted) {
                        res.fold(
                          (failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save rhyme: ${failure.message}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          (_) {
                            ref.invalidate(rhymesProvider);
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(RhymeModel rhyme) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Rhyme',
      message:
          'Are you sure you want to delete "${rhyme.titleLatin}"? This action cannot be undone.',
    );
    if (ok == true) {
      ref.read(rhymesProvider.notifier).deleteRhyme(rhyme.id);
    }
  }
}
