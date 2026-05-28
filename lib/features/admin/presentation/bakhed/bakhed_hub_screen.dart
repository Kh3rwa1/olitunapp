import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../data/bakhed_repository.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_empty_state.dart';
import '../../domain/content_badge_resolver.dart';
import '../widgets/content_type_badge.dart';

class BakhedHubScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  const BakhedHubScreen({super.key, this.categoryId});

  @override
  ConsumerState<BakhedHubScreen> createState() => _BakhedHubScreenState();
}

class _AdminWaveformPainter extends CustomPainter {
  final Color color;
  _AdminWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    const int bars = 25;
    final double spacing = width / bars;

    // A static decorative sound wave representation
    final heights = [
      0.3,
      0.4,
      0.6,
      0.8,
      0.5,
      0.3,
      0.4,
      0.7,
      0.9,
      0.6,
      0.4,
      0.3,
      0.5,
      0.8,
      0.7,
      0.5,
      0.4,
      0.6,
      0.8,
      0.5,
      0.3,
      0.4,
      0.6,
      0.5,
      0.3,
    ];

    for (int i = 0; i < bars; i++) {
      final double x = i * spacing;
      final double barHeight = height * heights[i % heights.length];
      final double yStart = (height - barHeight) / 2;
      final double yEnd = yStart + barHeight;
      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                      final newId = ID.unique();
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

                        return Card(
                          color: AdminTokens.raised(isDark),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AdminTokens.radiusMd,
                            ),
                            side: BorderSide(color: AdminTokens.border(isDark)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AdminTokens.radiusMd,
                            ),
                            onTap: () =>
                                context.go('/admin/bakhed/editor/${item.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: thumb + titles
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AdminTokens.sunken(isDark),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AdminTokens.radiusSm,
                                                  ),
                                              image:
                                                  item
                                                          .heroMedia
                                                          ?.url
                                                          .isNotEmpty ==
                                                      true
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        item.heroMedia!.url,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child:
                                                item
                                                        .heroMedia
                                                        ?.url
                                                        .isNotEmpty ==
                                                    true
                                                ? null
                                                : const Icon(
                                                    Icons.music_note_rounded,
                                                    color: AppColors.primary,
                                                    size: 28,
                                                  ),
                                          ),
                                          Positioned(
                                            bottom: -4,
                                            right: -4,
                                            child: ContentTypeBadge(
                                              type: resolveBadgeType(
                                                kind: item.kind,
                                                categoryId: item.categoryId,
                                              ),
                                              size: 24,
                                              hasShadowRing: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),

                                      // Titles
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: AdminTokens.cardTitle(
                                                isDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.titleOlChiki != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.titleOlChiki!,
                                                style: TextStyle(
                                                  fontFamily: 'OlChiki',
                                                  fontSize: 14,
                                                  color:
                                                      AdminTokens.textSecondary(
                                                        isDark,
                                                      ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Text(
                                              categoryName,
                                              style: AdminTokens.label(isDark)
                                                  .copyWith(
                                                    color:
                                                        AdminTokens.textTertiary(
                                                          isDark,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Audio Waveform decorator
                                  if (hasAudio) ...[
                                    SizedBox(
                                      height: 20,
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter: _AdminWaveformPainter(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ] else ...[
                                    Text(
                                      '(No Audio Track Uploaded)',
                                      style: AdminTokens.label(isDark).copyWith(
                                        color: AdminTokens.textMuted(isDark),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  const Divider(height: 12),

                                  // Status chips + actions row
                                  Row(
                                    children: [
                                      // Status Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isPublished
                                              ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.amber.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: item.isPublished
                                                ? Colors.green.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.amber.withValues(
                                                    alpha: 0.3,
                                                  ),
                                          ),
                                        ),
                                        child: Text(
                                          item.isPublished
                                              ? 'Published'
                                              : 'Draft',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: item.isPublished
                                                ? Colors.green
                                                : Colors.amber[800],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Premium Chip
                                      if (item.isPremium)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Text(
                                            'Premium',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      const Spacer(),

                                      // Edit button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                        ),
                                        color: AdminTokens.textSecondary(
                                          isDark,
                                        ),
                                        onPressed: () => context.go(
                                          '/admin/bakhed/editor/${item.id}',
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AdminTokens.sunken(
                                            isDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Delete button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                        ),
                                        color: Colors.red,
                                        onPressed: () =>
                                            _confirmDelete(context, ref, item),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red
                                              .withValues(alpha: 0.08),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ContentItem rhyme,
  ) async {
    BuildContext? countDialogContext;
    // Show a loading dialog while fetching subcollection counts
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        countDialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    // Yield execution to the event loop to allow the dialog route to build and assign context
    await Future.delayed(Duration.zero);

    int lyricsCount = 0;
    int vocabCount = 0;
    int notesCount = 0;

    try {
      final repo = ref.read(bakhedRepositoryProvider);
      final lyricsRes = await repo.getLyrics(rhyme.id);
      final vocabRes = await repo.getVocabulary(rhyme.id);
      final notesRes = await repo.getCulturalNotes(rhyme.id);

      lyricsCount = lyricsRes.fold((_) => 0, (l) => l.length);
      vocabCount = vocabRes.fold((_) => 0, (v) => v.length);
      notesCount = notesRes.fold((_) => 0, (n) => n.length);
    } finally {
      // Close the loading dialog using the captured dialogContext to avoid popping the parent route
      if (countDialogContext != null && countDialogContext!.mounted) {
        Navigator.of(countDialogContext!).pop();
      }
    }

    final totalChildCount = lyricsCount + vocabCount + notesCount;

    bool confirm = false;
    if (context.mounted) {
      confirm =
          await showDialog<bool>(
            context: context,
            builder: (context) => _DeleteConfirmationDialog(
              rhyme: rhyme,
              totalChildCount: totalChildCount,
              lyricsCount: lyricsCount,
              vocabCount: vocabCount,
              notesCount: notesCount,
            ),
          ) ??
          false;
    }

    if (confirm) {
      BuildContext? deleteDialogContext;
      bool isDeleteDialogPopped = false;

      // Show loading dialog for delete execution
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            deleteDialogContext = ctx;
            return const Center(child: CircularProgressIndicator());
          },
        );
        // Yield execution to the event loop to allow the dialog route to build and assign context
        await Future.delayed(Duration.zero);
      }

      try {
        final repo = ref.read(bakhedRepositoryProvider);
        final deleteRes = await repo.delete(rhyme.id);

        // Close loading dialog using the captured dialogContext to avoid popping the parent route
        if (deleteDialogContext != null &&
            deleteDialogContext!.mounted &&
            !isDeleteDialogPopped) {
          isDeleteDialogPopped = true;
          Navigator.of(deleteDialogContext!).pop();
        }

        deleteRes.fold(
          (failure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete failed: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Rhyme and associated subcollection items deleted successfully.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              ref.invalidate(contentListProvider((ContentKind.rhyme, null)));
            }
          },
        );
      } finally {
        // Defensive cleanup: guarantee the dialog is popped if not already popped
        if (deleteDialogContext != null &&
            deleteDialogContext!.mounted &&
            !isDeleteDialogPopped) {
          isDeleteDialogPopped = true;
          Navigator.of(deleteDialogContext!).pop();
        }
      }
    }
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final ContentItem rhyme;
  final int totalChildCount;
  final int lyricsCount;
  final int vocabCount;
  final int notesCount;

  const _DeleteConfirmationDialog({
    required this.rhyme,
    required this.totalChildCount,
    required this.lyricsCount,
    required this.vocabCount,
    required this.notesCount,
  });

  @override
  State<_DeleteConfirmationDialog> createState() =>
      __DeleteConfirmationDialogState();
}

class __DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = widget.totalChildCount > 20;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: AdminTokens.overlay(isDark),
      title: Text(
        'Delete Rhyme: ${widget.rhyme.title}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to permanently delete this rhyme and all associated media? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Associated Subcollection Items to Cascade Delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• Lyrics Lines: ${widget.lyricsCount}'),
            Text('• Vocabulary Words: ${widget.vocabCount}'),
            Text('• Cultural Notes: ${widget.notesCount}'),
            if (isLarge) ...[
              const SizedBox(height: 16),
              const Text(
                'This rhyme contains a large amount of learning content. Please type DELETE to confirm cascade deletion:',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (!isLarge || textController.text.trim() == 'DELETE')
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
