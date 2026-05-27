import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/media_picker_field.dart';
import 'controllers/bakhed_editor_controller.dart';

class BakhedEditorScreen extends ConsumerStatefulWidget {
  final String bakhedId;
  const BakhedEditorScreen({super.key, required this.bakhedId});

  @override
  ConsumerState<BakhedEditorScreen> createState() => _BakhedEditorScreenState();
}

class _BakhedEditorScreenState extends ConsumerState<BakhedEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final currentId = widget.bakhedId;
    if (_tabController.index == 2) {
      ref.read(bakhedLyricsEditorProvider(currentId).notifier).ensureLoaded();
    } else if (_tabController.index == 3) {
      ref
          .read(bakhedVocabularyEditorProvider(currentId).notifier)
          .ensureLoaded();
      ref.read(bakhedNotesEditorProvider(currentId).notifier).ensureLoaded();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(
      bakhedEditorControllerProvider(widget.bakhedId).notifier,
    );
    final result = await notifier.save();

    if (mounted) {
      if (result == SaveResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All changes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/admin/rhymes');
      } else if (result == SaveResult.concurrencyConflict) {
        final reload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AdminTokens.overlay(
              Theme.of(context).brightness == Brightness.dark,
            ),
            title: const Text('Save Conflict'),
            content: const Text(
              'Another administrator has updated this rhyme on the server since you opened it. Would you like to discard your local edits and reload the latest version?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reload latest'),
              ),
            ],
          ),
        );
        if (reload == true && mounted) {
          ref.invalidate(bakhedEditorControllerProvider(widget.bakhedId));
          ref.invalidate(bakhedLyricsEditorProvider(widget.bakhedId));
          ref.invalidate(bakhedVocabularyEditorProvider(widget.bakhedId));
          ref.invalidate(bakhedNotesEditorProvider(widget.bakhedId));

          ref
              .read(bakhedEditorControllerProvider(widget.bakhedId).notifier)
              .load();
          _onTabChanged();
        }
      } else if (result == SaveResult.uploadInProgress) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An audio upload is still in progress. Please wait for it to finish, then save again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final state = ref.read(bakhedEditorControllerProvider(widget.bakhedId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Failed to save changes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorState = ref.watch(
      bakhedEditorControllerProvider(widget.bakhedId),
    );
    final lyricsState = ref.watch(bakhedLyricsEditorProvider(widget.bakhedId));
    final vocabState = ref.watch(
      bakhedVocabularyEditorProvider(widget.bakhedId),
    );
    final notesState = ref.watch(bakhedNotesEditorProvider(widget.bakhedId));

    final isAnySubcollectionDirty =
        lyricsState.isDirty || vocabState.isDirty || notesState.isDirty;
    final isDirty = editorState.isDirty || isAnySubcollectionDirty;

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AdminTokens.overlay(isDark),
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes in this editor. Are you sure you want to exit and discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep Editing'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.go('/admin/rhymes');
        }
      },
      child: Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        appBar: AppBar(
          backgroundColor: AdminTokens.raised(isDark),
          title: editorState.item.when(
            data: (item) => Text(
              item.title.isNotEmpty ? 'Editing: ${item.title}' : 'New Rhyme',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => const Text('Loading Rhyme...'),
            error: (_, _) => const Text('Error'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (isDirty) {
                Navigator.of(context).maybePop();
              } else {
                context.go('/admin/rhymes');
              }
            },
          ),
          actions: [
            if (isDirty)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'Unsaved Changes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed:
                    (isDirty &&
                        !editorState.isSaving &&
                        !editorState.isUploading)
                    ? _handleSave
                    : null,
                icon: (editorState.isSaving || editorState.isUploading)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                label: Text(
                  editorState.isUploading ? 'Uploading…' : 'Save Changes',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AdminTokens.textSecondary(isDark),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline_rounded), text: 'Basics'),
              Tab(icon: Icon(Icons.audiotrack_rounded), text: 'Audio'),
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Lyrics'),
              Tab(icon: Icon(Icons.school_rounded), text: 'Learning'),
            ],
          ),
        ),
        body: editorState.item.when(
          data: (item) => TabBarView(
            controller: _tabController,
            children: [
              _BasicsTab(bakhedId: widget.bakhedId),
              _AudioTab(bakhedId: widget.bakhedId),
              _LyricsTab(bakhedId: widget.bakhedId),
              _LearningTab(bakhedId: widget.bakhedId),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error loading rhyme metadata: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. Basics Tab
// ==========================================

class _BasicsTab extends ConsumerStatefulWidget {
  final String bakhedId;
  const _BasicsTab({required this.bakhedId});

  @override
  ConsumerState<_BasicsTab> createState() => _BasicsTabState();
}

class _BasicsTabState extends ConsumerState<_BasicsTab> {
  late final TextEditingController _titleController;
  late final TextEditingController _titleOlChikiController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _olChikiController;

  @override
  void initState() {
    super.initState();
    final item = ref
        .read(bakhedEditorControllerProvider(widget.bakhedId))
        .item
        .value;
    _titleController = TextEditingController(text: item?.title ?? '');
    _titleOlChikiController = TextEditingController(
      text: item?.titleOlChiki ?? '',
    );
    _subtitleController = TextEditingController(text: item?.subtitle ?? '');
    _olChikiController = TextEditingController(text: item?.olChiki ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleOlChikiController.dispose();
    _subtitleController.dispose();
    _olChikiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = ref.watch(
      bakhedEditorControllerProvider(
        widget.bakhedId,
      ).select((s) => s.item.value),
    );
    if (item == null) return const SizedBox();

    final notifier = ref.read(
      bakhedEditorControllerProvider(widget.bakhedId).notifier,
    );
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Card(
          color: AdminTokens.raised(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            side: BorderSide(color: AdminTokens.border(isDark)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Basic Metadata', style: AdminTokens.sectionTitle(isDark)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        onChanged: notifier.updateTitle,
                        decoration: InputDecoration(
                          labelText: 'Title (Latin)*',
                          hintText: 'Enter Latin title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AdminTokens.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _titleOlChikiController,
                        onChanged: notifier.updateTitleOlChiki,
                        decoration: InputDecoration(
                          labelText: 'Title (Ol Chiki)',
                          hintText: 'Enter Ol Chiki title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AdminTokens.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: categoriesAsync.when(
                        data: (categories) {
                          return DropdownButtonFormField<String>(
                            initialValue:
                                categories.any((c) => c.id == item.categoryId)
                                ? item.categoryId
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Category*',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AdminTokens.radiusSm,
                                ),
                              ),
                            ),
                            items: categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.titleLatin),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                notifier.updateCategoryId(val);
                              }
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) =>
                            Text('Error loading categories: $err'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Premium Access'),
                        subtitle: const Text('Requires subscription to unlock'),
                        value: item.isPremium,
                        activeThumbColor: AppColors.primary,
                        onChanged: notifier.updateIsPremium,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          side: BorderSide(color: AdminTokens.border(isDark)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: AdminTokens.raised(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            side: BorderSide(color: AdminTokens.border(isDark)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover & Artwork',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                const SizedBox(height: 20),
                MediaPickerField(
                  label: 'Cover Image (Thumbnail)',
                  kind: ContentMediaKind.image,
                  value: item.heroMedia,
                  onRemove: notifier.markForDeletion,
                  onChanged: notifier.updateThumbnail,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. Audio Tab
// ==========================================

class _AudioTab extends ConsumerWidget {
  final String bakhedId;
  const _AudioTab({required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = ref.watch(
      bakhedEditorControllerProvider(bakhedId).select((s) => s.item.value),
    );
    if (item == null) return const SizedBox();

    final notifier = ref.read(
      bakhedEditorControllerProvider(bakhedId).notifier,
    );
    final hasAudio = item.audioUrl != null && item.audioUrl!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Card(
          color: AdminTokens.raised(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
            side: BorderSide(color: AdminTokens.border(isDark)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhyme Audio Track',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload an MP3 play-along audio file. This will enable synchronized scrolling lyrics and word-by-word reading highlighting in the learner interface.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                MediaPickerField(
                  label: 'Audio File (MP3)',
                  kind: ContentMediaKind.audio,
                  value: item.audioUrl != null && item.audioUrl!.isNotEmpty
                      ? ContentMedia(
                          url: item.audioUrl!,
                          fileId: item.audioFileId ?? '',
                          kind: ContentMediaKind.audio,
                        )
                      : null,
                  onUploadStateChanged: notifier.setUploadInProgress,
                  onRemove: notifier.markForDeletion,
                  onChanged: (media) {
                    notifier.updateAudio(
                      media?.url,
                      media?.fileId,
                      media?.durationMs ??
                          (media?.durationSeconds != null
                              ? media!.durationSeconds! * 1000
                              : null),
                    );
                    if (media?.url != null && media!.url.isNotEmpty) {
                      ref
                          .read(bakhedAudioPlayerProvider(bakhedId))
                          .setUrl(media.url)
                          .catchError((_) => null);
                    }
                  },
                ),

                if (hasAudio) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Audio Playback Preview',
                    style: AdminTokens.sectionTitle(isDark),
                  ),
                  const SizedBox(height: 16),
                  _SyncedAudioPlayerWidget(bakhedId: bakhedId),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
    const int bars = 40;
    final double spacing = width / bars;

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

class _SyncedAudioPlayerWidget extends ConsumerWidget {
  final String bakhedId;
  const _SyncedAudioPlayerWidget({required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(bakhedAudioPlayerProvider(bakhedId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          initialData: player.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.positionStream,
              initialData: player.position,
              builder: (context, positionSnapshot) {
                var position = positionSnapshot.data ?? Duration.zero;
                if (position > duration) {
                  position = duration;
                }

                String formatDuration(Duration d) {
                  final minutes = d.inMinutes
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  final seconds = d.inSeconds
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  return '$minutes:$seconds';
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _AdminWaveformPainter(
                          color: playing
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            if (playing) {
                              player.pause();
                            } else {
                              player.play();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatDuration(position),
                          style: AdminTokens.body(isDark).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            max: duration.inMilliseconds.toDouble() > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              player.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Text(
                          formatDuration(duration),
                          style: AdminTokens.body(isDark).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. Lyrics Timeline Editor Tab
// ==========================================

class _LyricsTab extends ConsumerStatefulWidget {
  final String bakhedId;
  const _LyricsTab({required this.bakhedId});

  @override
  ConsumerState<_LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends ConsumerState<_LyricsTab> {
  int? _focusedRowIndex;

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  Future<void> _showBulkPasteDialog() async {
    final textController = TextEditingController();
    bool replaceAll = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AdminTokens.overlay(
                Theme.of(context).brightness == Brightness.dark,
              ),
              title: const Text('Bulk Paste Lyrics'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Format: Ol Chiki | Latin | English Meaning (One per line)',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Example: ᱚᱞ ᱪᱤᱠᱤ | latin text | english meaning',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'ᱚᱞ ᱪᱤᱠᱤ | latin | meaning\nᱚᱞ ᱪᱤᱠᱤ | latin | meaning',
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Replace existing lyrics'),
                      subtitle: const Text(
                        'Warning: this will delete all currently marked lines',
                      ),
                      value: replaceAll,
                      onChanged: (val) {
                        setState(() {
                          replaceAll = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(
                      bakhedLyricsEditorProvider(widget.bakhedId).notifier,
                    );
                    notifier.bulkPaste(
                      textController.text,
                      replace: replaceAll,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lyricsState = ref.watch(bakhedLyricsEditorProvider(widget.bakhedId));
    final lyricsNotifier = ref.read(
      bakhedLyricsEditorProvider(widget.bakhedId).notifier,
    );
    final player = ref.watch(bakhedAudioPlayerProvider(widget.bakhedId));
    final item = ref.watch(
      bakhedEditorControllerProvider(
        widget.bakhedId,
      ).select((s) => s.item.value),
    );
    final durationMs = item?.durationMs ?? 0;

    if (!lyricsState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Timeline Player Bar
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            initialData: player.playerState,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final playing = playerState?.playing ?? false;

              return StreamBuilder<Duration?>(
                stream: player.durationStream,
                initialData: player.duration,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    initialData: player.position,
                    builder: (context, positionSnapshot) {
                      var position = positionSnapshot.data ?? Duration.zero;
                      if (position > duration) position = duration;

                      return Card(
                        color: AdminTokens.raised(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusMd,
                          ),
                          side: BorderSide(color: AdminTokens.border(isDark)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      playing
                                          ? Icons.pause_circle_outline_rounded
                                          : Icons.play_circle_outline_rounded,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                    onPressed: () => playing
                                        ? player.pause()
                                        : player.play(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatMs(position.inMilliseconds),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: position.inMilliseconds.toDouble(),
                                      max:
                                          duration.inMilliseconds.toDouble() > 0
                                          ? duration.inMilliseconds.toDouble()
                                          : 1.0,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) => player.seek(
                                        Duration(milliseconds: val.toInt()),
                                      ),
                                    ),
                                  ),
                                  Text(_formatMs(duration.inMilliseconds)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.timer_rounded,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Mark Line Start',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      final currentPos =
                                          position.inMilliseconds;
                                      final focusIdx = _focusedRowIndex ?? 0;
                                      if (focusIdx <
                                          lyricsState.currentLines.length) {
                                        final lines =
                                            List<BakhedLyricLine>.from(
                                              lyricsState.currentLines,
                                            );
                                        lines[focusIdx] = lines[focusIdx]
                                            .copyWith(startMs: currentPos);
                                        lyricsNotifier.updateLines(lines);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Marked line ${focusIdx + 1} at ${_formatMs(currentPos)}',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 700,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );

                                        setState(() {
                                          if (focusIdx <
                                              lyricsState.currentLines.length -
                                                  1) {
                                            _focusedRowIndex = focusIdx + 1;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.content_paste_rounded,
                                        ),
                                        label: const Text('Bulk Paste'),
                                        onPressed: _showBulkPasteDialog,
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Add Line'),
                                        onPressed: () {
                                          final currentIdx =
                                              lyricsState.currentLines.length;
                                          final defaultStart = currentIdx > 0
                                              ? lyricsState
                                                        .currentLines
                                                        .last
                                                        .startMs +
                                                    5000
                                              : 0;
                                          final newLine = BakhedLyricLine(
                                            id: '',
                                            lineIndex: currentIdx,
                                            startMs: defaultStart,
                                            endMs: defaultStart + 5000,
                                            olChiki: '',
                                            latin: '',
                                            meaning: '',
                                          );
                                          lyricsNotifier.addLine(newLine);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Header Row
          const Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'StartMs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'EndMs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Ol Chiki',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  'Latin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  'Meaning',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 100),
            ],
          ),
          const SizedBox(height: 8),

          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: lyricsState.currentLines.length,
              // ignore: deprecated_member_use
              onReorder: lyricsNotifier.reorderLines,
              itemBuilder: (context, index) {
                final line = lyricsState.currentLines[index];
                final isFocused = _focusedRowIndex == index;
                final derivedEndMs = index < lyricsState.currentLines.length - 1
                    ? lyricsState.currentLines[index + 1].startMs
                    : durationMs;

                return MouseRegion(
                  key: ValueKey('line_${line.id}_$index'),
                  child: Card(
                    color: isFocused
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AdminTokens.raised(isDark),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      side: BorderSide(
                        color: isFocused
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AdminTokens.border(isDark),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _focusedRowIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            // Selection index
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: isFocused
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isFocused
                                        ? AppColors.primary
                                        : AdminTokens.textPrimary(isDark),
                                  ),
                                ),
                              ),
                            ),

                            // StartMs input
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: line.startMs.toString(),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final numVal =
                                      int.tryParse(val) ?? line.startMs;
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    startMs: numVal,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Derived EndMs
                            SizedBox(
                              width: 90,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  _formatMs(derivedEndMs),
                                  style: TextStyle(
                                    color: AdminTokens.textTertiary(isDark),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Ol Chiki text
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: line.olChiki,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    olChiki: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Latin text
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: line.latin,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    latin: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Meaning text
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: line.meaning,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final lines = List<BakhedLyricLine>.from(
                                    lyricsState.currentLines,
                                  );
                                  lines[index] = lines[index].copyWith(
                                    meaning: val,
                                  );
                                  lyricsNotifier.updateLines(lines);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () {
                                lyricsNotifier.removeLine(
                                  line.id,
                                  line.lineIndex,
                                );
                                if (isFocused) {
                                  setState(() {
                                    _focusedRowIndex = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. Learning Tab (Vocabulary + Cultural Notes)
// ==========================================

class _LearningTab extends ConsumerWidget {
  final String bakhedId;
  const _LearningTab({required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabState = ref.watch(bakhedVocabularyEditorProvider(bakhedId));
    final notesState = ref.watch(bakhedNotesEditorProvider(bakhedId));

    if (!vocabState.isLoaded || !notesState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Vocabulary list section
        _VocabularyCard(bakhedId: bakhedId),
        const SizedBox(height: 24),

        // Cultural Notes list section
        _CulturalNotesCard(bakhedId: bakhedId),
      ],
    );
  }
}

class _VocabularyCard extends ConsumerWidget {
  final String bakhedId;
  const _VocabularyCard({required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(bakhedVocabularyEditorProvider(bakhedId));
    final notifier = ref.read(
      bakhedVocabularyEditorProvider(bakhedId).notifier,
    );

    return Card(
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vocabulary List',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Add Word',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final newIdx = state.currentItems.length;
                    final newItem = BakhedVocabularyItem(
                      id: '',
                      olChiki: '',
                      latin: '',
                      meaning: '',
                      audioFileId: '',
                      sortOrder: newIdx,
                    );
                    notifier.addItem(newItem);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.currentItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No vocabulary words added yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.currentItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.currentItems[index];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        // Index
                        Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),

                        // Ol Chiki field
                        Expanded(
                          child: TextFormField(
                            initialValue: item.olChiki,
                            decoration: const InputDecoration(
                              labelText: 'Ol Chiki',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                olChiki: val,
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Latin transliteration
                        Expanded(
                          child: TextFormField(
                            initialValue: item.latin,
                            decoration: const InputDecoration(
                              labelText: 'Latin',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(latin: val);
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Meaning
                        Expanded(
                          child: TextFormField(
                            initialValue: item.meaning,
                            decoration: const InputDecoration(
                              labelText: 'Meaning',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                meaning: val,
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Audio file picker / field (pronunciation)
                        SizedBox(
                          width: 150,
                          child: MediaPickerField(
                            label: 'Pronunciation',
                            kind: ContentMediaKind.audio,
                            value: item.audioFileId.isNotEmpty
                                // Using a simplified wrapper
                                ? ContentMedia(
                                    url: '',
                                    fileId: item.audioFileId,
                                    kind: ContentMediaKind.audio,
                                  )
                                : null,
                            onRemove: (fileId) {
                              ref
                                  .read(
                                    bakhedEditorControllerProvider(
                                      bakhedId,
                                    ).notifier,
                                  )
                                  .markForDeletion(fileId);
                            },
                            onChanged: (media) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                audioFileId: media?.fileId ?? '',
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              notifier.removeItem(item.id, item.sortOrder),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CulturalNotesCard extends ConsumerWidget {
  final String bakhedId;
  const _CulturalNotesCard({required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(bakhedNotesEditorProvider(bakhedId));
    final notifier = ref.read(bakhedNotesEditorProvider(bakhedId).notifier);

    return Card(
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cultural Notes & Context',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Add Note',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    const newNote = BakhedCulturalNote(
                      noteId: '',
                      title: '',
                      body: '',
                      source: '',
                      isPublished: true,
                    );
                    notifier.addNote(newNote);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.currentNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No cultural notes added yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.currentNotes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final note = state.currentNotes[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Index
                            Text(
                              'Note #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            // Publish Switch
                            Row(
                              children: [
                                Switch(
                                  value: note.isPublished,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) {
                                    final notes = List<BakhedCulturalNote>.from(
                                      state.currentNotes,
                                    );
                                    notes[index] = notes[index].copyWith(
                                      isPublished: val,
                                    );
                                    notifier.updateNotes(notes);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Published',
                                  style: AdminTokens.label(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Delete note
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              onPressed: () => notifier.removeNote(note.noteId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title field
                        TextFormField(
                          initialValue: note.title,
                          decoration: const InputDecoration(
                            labelText: 'Note Title*',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(title: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Source field
                        TextFormField(
                          initialValue: note.source,
                          decoration: const InputDecoration(
                            labelText: 'Source / Author',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(source: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Body field (markdown rich text)
                        TextFormField(
                          initialValue: note.body,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Note Body (Markdown Support)*',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(body: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
