part of 'bakhed_hub_screen.dart';

// Section builders and helper widgets extracted from the bakhed hub screen.

extension _BakhedHubSections on _BakhedHubScreenState {
  Widget _buildRhymeCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ContentItem item,
    String categoryName,
    bool hasAudio,
  ) {
    return Card(
      color: AdminTokens.raised(isDark),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        onTap: () => context.go('/admin/bakhed/editor/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: thumb + titles
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          child: CoverThumbnail(
                            media: item.heroMedia,
                            coverMediaType: item.coverMediaType,
                            fallback: const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AdminTokens.cardTitle(isDark),
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
                              color: AdminTokens.textSecondary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          categoryName,
                          style: AdminTokens.label(
                            isDark,
                          ).copyWith(color: AdminTokens.textTertiary(isDark)),
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
                      color: AppColors.primary.withValues(alpha: 0.35),
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
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.isPublished
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      item.isPublished ? 'Published' : 'Draft',
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
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
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: AdminTokens.textSecondary(isDark),
                    tooltip: 'Edit rhyme',
                    onPressed: () =>
                        context.go('/admin/bakhed/editor/${item.id}'),
                    style: IconButton.styleFrom(
                      backgroundColor: AdminTokens.sunken(isDark),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.red,
                    tooltip: 'Delete rhyme',
                    onPressed: () => _confirmDelete(context, ref, item),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                    ),
                  ),
                ],
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
