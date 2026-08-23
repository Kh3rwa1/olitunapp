import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/bakhed_audio_tab.dart';
import 'widgets/bakhed_learning_tab.dart';
import 'widgets/bakhed_lyrics_tab.dart';
import 'controllers/bakhed_editor_controller.dart';
import 'widgets/bakhed_basics_tab.dart';

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
              editorState.isNewDraft && item.title.isEmpty
                  ? 'New Rhyme'
                  : 'Editing: ${item.title}',
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
              BakhedBasicsTab(bakhedId: widget.bakhedId),
              BakhedAudioTab(bakhedId: widget.bakhedId),
              BakhedLyricsTab(bakhedId: widget.bakhedId),
              BakhedLearningTab(bakhedId: widget.bakhedId),
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
