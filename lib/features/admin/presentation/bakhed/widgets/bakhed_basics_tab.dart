import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../controllers/bakhed_editor_controller.dart';

import 'bakhed_category_field.dart';
import '../../widgets/media_picker_field.dart';

/// Basics tab of the Bakhed editor: title, category, and cover fields.
class BakhedBasicsTab extends ConsumerStatefulWidget {
  final String bakhedId;
  const BakhedBasicsTab({super.key, required this.bakhedId});

  @override
  ConsumerState<BakhedBasicsTab> createState() => _BakhedBasicsTabState();
}

class _BakhedBasicsTabState extends ConsumerState<BakhedBasicsTab> {
  late final TextEditingController _titleController;
  late final TextEditingController _titleOlChikiController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _olChikiController;

  int _selectedCoverTab = 0;
  bool _hasInitializedFromState = false;

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

    if (!_hasInitializedFromState) {
      _selectedCoverTab = item.coverMediaType == 'video' ? 1 : 0;
      _hasInitializedFromState = true;
    }

    final notifier = ref.read(
      bakhedEditorControllerProvider(widget.bakhedId).notifier,
    );

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
                      child: BakhedCategoryField(
                        initialValue:
                            item.category ??
                            (item.categoryId.isNotEmpty
                                ? item.categoryId
                                : null),
                        onChanged: notifier.updateCategory,
                        enabled: !ref.watch(
                          bakhedEditorControllerProvider(
                            widget.bakhedId,
                          ).select((s) => s.isSaving),
                        ),
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
                Text(
                  'Cover Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Image Cover'),
                      icon: Icon(Icons.image_outlined),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Video Loop Cover'),
                      icon: Icon(Icons.play_circle_outline),
                    ),
                  ],
                  selected: {_selectedCoverTab},
                  onSelectionChanged: (newSelection) {
                    _handleTabChange(newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.15,
                    ),
                    selectedForegroundColor: AppColors.primary,
                    visualDensity: VisualDensity.comfortable,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedCoverTab == 0)
                  MediaPickerField(
                    label: 'Cover Image (Thumbnail)',
                    kind: ContentMediaKind.image,
                    value: item.coverMediaType == 'image'
                        ? item.heroMedia
                        : null,
                    onRemove: notifier.markForDeletion,
                    onChanged: (media) {
                      if (media == null) {
                        notifier.clearCover();
                      } else {
                        notifier.updateCoverMedia(media, 'image');
                      }
                    },
                  )
                else
                  MediaPickerField(
                    label: 'Cover Video Loop (Autoplay)',
                    kind: ContentMediaKind.video,
                    value: item.coverMediaType == 'video'
                        ? item.heroMedia
                        : null,
                    onRemove: notifier.markForDeletion,
                    onChanged: (media) {
                      if (media == null) {
                        notifier.clearCover();
                      } else {
                        notifier.updateCoverMedia(media, 'video');
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleTabChange(int newTab) {
    if (_selectedCoverTab == newTab) return;

    final item = ref
        .read(bakhedEditorControllerProvider(widget.bakhedId))
        .item
        .value;
    final notifier = ref.read(
      bakhedEditorControllerProvider(widget.bakhedId).notifier,
    );

    if (item == null) return;

    if (item.heroMedia == null) {
      setState(() {
        _selectedCoverTab = newTab;
      });
      return;
    }

    final targetMediaType = newTab == 0 ? 'image' : 'video';
    final currentMediaType = _selectedCoverTab == 0 ? 'image' : 'video';

    late BuildContext dialogContext;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;
        return AlertDialog(
          title: const Text('Change Cover Media Type?'),
          content: Text(
            'Switching to a $targetMediaType cover will permanently delete your existing $currentMediaType cover. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        notifier.clearCover();
        setState(() {
          _selectedCoverTab = newTab;
        });
      }
    });
  }
}

// ==========================================
// 2. Audio Tab
// ==========================================
