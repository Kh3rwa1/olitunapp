// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/features/admin/data/tracing_templates.dart';
import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/features/admin/presentation/widgets/tracing_stroke_editor.dart';
import 'package:itun/shared/providers/providers.dart';

import 'content_form/content_block_list_section.dart';
import 'content_form/content_form_card.dart';
import 'content_form/content_form_identity_section.dart';

class ContentForm extends ConsumerStatefulWidget {
  final ContentKind kind;
  final String? categoryId;
  final ContentItem? initial;
  final Future<void> Function(ContentItem) onSubmit;

  const ContentForm({
    super.key,
    required this.kind,
    this.categoryId,
    this.initial,
    required this.onSubmit,
  });

  @override
  ConsumerState<ContentForm> createState() => _ContentFormState();
}

class _ContentFormState extends ConsumerState<ContentForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _titleOlChikiController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _olChikiController;
  late final TextEditingController _orderController;

  String? _selectedCategoryId;
  bool _isPublished = false;
  bool _isPremium = false;
  final List<String> _tags = [];

  ContentMedia? _heroMedia;
  TracingConfig? _tracingConfig;
  final List<ContentBlock> _blocks = [];

  // Deferred deletion queue: files marked for removal are only deleted after
  // a successful save commit, preventing orphaned or missing media on cancel/abort.
  final Set<String> _pendingDeletions = {};

  bool get _requiresCategory =>
      widget.kind != ContentKind.letter && widget.kind != ContentKind.number;

  String get glyphValue =>
      _olChikiController.text.isNotEmpty ? _olChikiController.text : 'ᱚ';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _titleOlChikiController = TextEditingController(
      text: widget.initial?.titleOlChiki ?? '',
    );
    _subtitleController = TextEditingController(
      text: widget.initial?.subtitle ?? '',
    );
    _olChikiController = TextEditingController(
      text: widget.initial?.olChiki ?? '',
    );
    _orderController = TextEditingController(
      text: (widget.initial?.order ?? 0).toString(),
    );

    _selectedCategoryId =
        (widget.initial != null && widget.initial!.categoryId.isNotEmpty)
        ? widget.initial!.categoryId
        : (widget.categoryId?.isNotEmpty == true ? widget.categoryId : null);
    _isPublished = widget.initial?.isPublished ?? false;
    _isPremium = widget.initial?.isPremium ?? false;
    if (widget.initial?.tags != null) {
      _tags.addAll(widget.initial!.tags);
    }

    _heroMedia = widget.initial?.heroMedia;
    _tracingConfig = widget.initial?.tracing;
    if (widget.initial?.blocks != null) {
      _blocks.addAll(widget.initial!.blocks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleOlChikiController.dispose();
    _subtitleController.dispose();
    _olChikiController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      final fallback = widget.categoryId;
      if (fallback != null && fallback.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedCategoryId = fallback;
            });
          }
        });
      }
    }
  }

  void _markForDeletion(String fileId) {
    if (fileId.trim().isNotEmpty) {
      _pendingDeletions.add(fileId.trim());
    }
  }

  void _addTag(String tag) {
    final clean = tag.trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addBlock(ContentBlock block) {
    setState(() {
      _blocks.add(block);
    });
  }

  void _removeBlock(int index) {
    setState(() {
      final removed = _blocks.removeAt(index);
      // If the removed block had associated media, queue it for deferred deletion
      if (removed is ImageBlock && removed.media.fileId.isNotEmpty) {
        _markForDeletion(removed.media.fileId);
      } else if (removed is VideoBlock && removed.media.fileId.isNotEmpty) {
        _markForDeletion(removed.media.fileId);
      } else if (removed is AudioBlock && removed.media.fileId.isNotEmpty) {
        _markForDeletion(removed.media.fileId);
      } else if (removed is LottieBlock && removed.media.fileId.isNotEmpty) {
        _markForDeletion(removed.media.fileId);
      }
    });
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  void _updateBlock(int index, ContentBlock block) {
    setState(() {
      _blocks[index] = block;
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final needTracing =
        widget.kind == ContentKind.letter || widget.kind == ContentKind.number;

    if (needTracing && _tracingConfig == null) {
      _showStrokesBlockingModal();
      return;
    }

    final resolvedCategoryId =
        (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty)
        ? _selectedCategoryId!
        : widget.categoryId;

    if (_requiresCategory &&
        (resolvedCategoryId == null || resolvedCategoryId.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category before saving.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final item = ContentItem(
      id: widget.initial?.id ?? const Uuid().v4(),
      kind: widget.kind,
      categoryId: resolvedCategoryId ?? widget.kind.name,
      title: _titleController.text.trim(),
      titleOlChiki: _titleOlChikiController.text.trim().isNotEmpty
          ? _titleOlChikiController.text.trim()
          : null,
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      olChiki: _olChikiController.text.trim().isNotEmpty
          ? _olChikiController.text.trim()
          : null,
      heroMedia: _heroMedia,
      blocks: List.unmodifiable(_blocks),
      tracing: _tracingConfig,
      order: int.tryParse(_orderController.text) ?? 0,
      isPublished: _isPublished,
      isPremium: _isPremium,
      tags: List.unmodifiable(_tags),
      updatedAt: DateTime.now(),
    );

    await widget.onSubmit(item);

    // Commit deferred deletions after successful form submission
    _commitPendingDeletions();
  }

  void _commitPendingDeletions() {
    if (_pendingDeletions.isEmpty) return;
    final toDelete = List<String>.from(_pendingDeletions);
    _pendingDeletions.clear();

    final uploader = ref.read(mediaUploaderProvider);
    Future.microtask(() async {
      for (final fileId in toDelete) {
        try {
          final res = await uploader.deleteIfUnreferenced(
            fileId: fileId,
            checks: const [
              ReferenceCheck(
                databaseId: 'olitun_db',
                collectionId: 'lessons',
                fieldNames: ['thumbnailUrl', 'heroMediaUrl'],
              ),
              ReferenceCheck(
                databaseId: 'olitun_db',
                collectionId: 'rhymes',
                fieldNames: ['audioFileId', 'thumbnailUrl'],
              ),
            ],
          );
          res.fold(
            (f) => AppLogger.debug(
              'Failed to clean up pending media file $fileId: ${f.message}',
              name: 'ContentForm',
            ),
            (_) => AppLogger.debug(
              'Successfully cleaned up pending media file $fileId',
              name: 'ContentForm',
            ),
          );
        } catch (e) {
          AppLogger.debug(
            'Error cleaning up pending media file $fileId: $e',
            name: 'ContentForm',
          );
        }
      }
    });
  }

  void _showStrokesBlockingModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tracing Strokes Required'),
          content: Text(
            'This content type (${widget.kind.name}) requires standard tracing configuration. '
            'Would you like to pre-fill standard templates for $glyphValue now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final template =
                    tracingTemplates[glyphValue] ??
                    getFallbackTemplate(glyphValue);
                setState(() {
                  _tracingConfig = template;
                });
                Navigator.pop(context);
                _notifyTemplateSaved();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text(
                'Pre-fill & Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _notifyTemplateSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preset Tracing template pre-filled for $glyphValue! Click save again to finalize.',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 - Identity Details
            ContentFormIdentitySection(
              isDark: isDark,
              kind: widget.kind,
              titleController: _titleController,
              titleOlChikiController: _titleOlChikiController,
              subtitleController: _subtitleController,
              olChikiController: _olChikiController,
              orderController: _orderController,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (val) =>
                  setState(() => _selectedCategoryId = val),
              isPublished: _isPublished,
              onPublishedChanged: (val) => setState(() => _isPublished = val),
              isPremium: _isPremium,
              onPremiumChanged: (val) => setState(() => _isPremium = val),
              tags: _tags,
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
              categories: categories,
            ),
            const SizedBox(height: 16),

            // Section 2 - Hero Media
            ContentFormCard(
              isDark: isDark,
              title: 'Hero Cover Media',
              child: MediaPickerField(
                label: 'Cover Visual Element',
                kind: widget.kind == ContentKind.lesson
                    ? ContentMediaKind.video
                    : ContentMediaKind.image,
                value: _heroMedia,
                onRemove: _markForDeletion,
                onChanged: (media) {
                  setState(() {
                    _heroMedia = media;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Section 3 - Tracing config (Letters & Numbers only)
            if (widget.kind == ContentKind.letter ||
                widget.kind == ContentKind.number) ...[
              ContentFormCard(
                isDark: isDark,
                title: 'Strokes & Tracing Engine',
                child: TracingStrokeEditor(
                  glyph: glyphValue,
                  initial: _tracingConfig,
                  onChanged: (config) {
                    setState(() {
                      _tracingConfig = config;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 4 - Rich Blocks List
            ContentBlockListSection(
              isDark: isDark,
              blocks: _blocks,
              glyphValue: glyphValue,
              onAddBlock: _addBlock,
              onRemoveBlock: _removeBlock,
              onReorderBlocks: _reorderBlocks,
              onUpdateBlock: _updateBlock,
              onMarkForDeletion: _markForDeletion,
            ),
            const SizedBox(height: 32),

            // Save row
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Save Content',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
