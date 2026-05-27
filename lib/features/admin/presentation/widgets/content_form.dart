// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/features/admin/presentation/widgets/tracing_stroke_editor.dart';
import 'package:itun/features/admin/data/tracing_templates.dart';
import 'package:itun/shared/providers/providers.dart';

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

  bool get _requiresCategory =>
      widget.kind != ContentKind.letter && widget.kind != ContentKind.number;
  bool get _supportsPublished => widget.kind != ContentKind.rhyme;
  bool get _supportsPremium =>
      widget.kind == ContentKind.lesson || widget.kind == ContentKind.rhyme;
  bool get _supportsSubtitle => widget.kind != ContentKind.number;
  bool get _supportsOrder => widget.kind != ContentKind.rhyme;
  bool get _supportsTags => widget.kind == ContentKind.rhyme;

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
    // Once the categories provider resolves, if we still have no selected
    // category in the dropdown, try to sync _selectedCategoryId so the
    // dropdown renders the correct pre-selected value.
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
      _blocks.removeAt(index);
    });
  }

  void _showAddBlockBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Rich Media Block',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildBlockTypeButton(Icons.text_fields_rounded, 'Text', () {
                    _addBlock(
                      TextBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        markdown: '',
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.image_rounded, 'Image', () {
                    _addBlock(
                      ImageBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        media: const ContentMedia(
                          url: '',
                          fileId: '',
                          kind: ContentMediaKind.image,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(
                    Icons.video_library_rounded,
                    'Video',
                    () {
                      _addBlock(
                        VideoBlock(
                          id: const Uuid().v4(),
                          order: _blocks.length,
                          media: const ContentMedia(
                            url: '',
                            fileId: '',
                            kind: ContentMediaKind.video,
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildBlockTypeButton(Icons.audiotrack_rounded, 'Audio', () {
                    _addBlock(
                      AudioBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        media: const ContentMedia(
                          url: '',
                          fileId: '',
                          kind: ContentMediaKind.audio,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.animation_rounded, 'Lottie', () {
                    _addBlock(
                      LottieBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        media: const ContentMedia(
                          url: '',
                          fileId: '',
                          kind: ContentMediaKind.lottie,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.quiz_rounded, 'Quiz', () {
                    _addBlock(
                      QuizBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        quizId: '',
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.abc_rounded, 'Glyph', () {
                    _addBlock(
                      GlyphBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        olChiki: '',
                        latin: '',
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(
                    Icons.info_outline_rounded,
                    'Callout',
                    () {
                      _addBlock(
                        CalloutBlock(
                          id: const Uuid().v4(),
                          order: _blocks.length,
                          text: '',
                          variant: CalloutVariant.note,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildBlockTypeButton(Icons.gesture_rounded, 'Tracing', () {
                    _addBlock(
                      TracingBlock(
                        id: const Uuid().v4(),
                        order: _blocks.length,
                        config: TracingConfig(
                          glyph: glyphValue,
                          strokes: const [],
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String get glyphValue =>
      _olChikiController.text.isNotEmpty ? _olChikiController.text : 'ᱚ';

  Widget _buildBlockTypeButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final needTracing =
        widget.kind == ContentKind.letter || widget.kind == ContentKind.number;

    if (needTracing && _tracingConfig == null) {
      // Show blocking strokes modal
      _showStrokesBlockingModal();
      return;
    }

    // Resolve categoryId: prefer dropdown selection, fall back to parent-provided value
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
            // Section 1 - Identity Card
            _buildCard(
              isDark: isDark,
              title: 'Identity Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (Latin)*',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Latin title is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Collapsible Advanced section for Lessons
                  if (widget.kind == ContentKind.lesson) ...[
                    ExpansionTile(
                      title: const Text(
                        'Advanced Titles (Ol Chiki, Glyphs)',
                        style: TextStyle(fontSize: 14),
                      ),
                      children: [
                        TextFormField(
                          controller: _titleOlChikiController,
                          decoration: const InputDecoration(
                            labelText: 'Title (Ol Chiki)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _olChikiController,
                          decoration: const InputDecoration(
                            labelText: 'Single Character Glyph (e.g. ᱚ)',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _titleOlChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Ol Chiki)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _olChikiController,
                      decoration: const InputDecoration(
                        labelText: 'Single Character Glyph (e.g. ᱚ)',
                      ),
                    ),
                  ],

                  if (_supportsSubtitle) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle / Translation / Summary',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_requiresCategory) ...[
                    // If categories have not loaded but this route supplied a
                    // category, preserve it rather than blocking a save.
                    if (categories.isEmpty && _selectedCategoryId != null)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Category*',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          'Category set: $_selectedCategoryId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value:
                            categories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        items: categories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.titleLatin),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category*',
                        ),
                        validator: (val) {
                          final effective = val ?? _selectedCategoryId;
                          if (effective == null || effective.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  if (_supportsPublished || _supportsPremium)
                    Row(
                      children: [
                        if (_supportsPublished)
                          Expanded(
                            child: SwitchListTile(
                              title: const Text(
                                'Published',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _isPublished,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) =>
                                  setState(() => _isPublished = val),
                            ),
                          ),
                        if (_supportsPremium)
                          Expanded(
                            child: SwitchListTile(
                              title: const Text(
                                'Premium',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _isPremium,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (val) =>
                                  setState(() => _isPremium = val),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  if (_supportsOrder) ...[
                    TextFormField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: 'Sort Order Index',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_supportsTags) _buildTagsField(isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2 - Hero Media
            _buildCard(
              isDark: isDark,
              title: 'Hero Cover Media',
              child: MediaPickerField(
                label: 'Cover Visual Element',
                kind: widget.kind == ContentKind.lesson
                    ? ContentMediaKind.video
                    : ContentMediaKind.image,
                value: _heroMedia,
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
              _buildCard(
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
            _buildCard(
              isDark: isDark,
              title: 'Rich Multimedia Blocks',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_blocks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No dynamic media blocks yet. Click button below to populate rich lessons content.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ReorderableListView(
                        shrinkWrap: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = _blocks.removeAt(oldIndex);
                            _blocks.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < _blocks.length; i++)
                            ListTile(
                              key: Key(_blocks[i].id),
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.12),
                                foregroundColor: const Color(0xFF10B981),
                                child: Text('${i + 1}'),
                              ),
                              title: Text(
                                _blocks[i].type.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: _buildBlockSubtitle(_blocks[i]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.drag_handle),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeBlock(i),
                                  ),
                                ],
                              ),
                              onTap: () => _editBlockInline(context, i),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddBlockBottomSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Content Block'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
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
                  foregroundColor: Colors.white,
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

  Widget _buildCard({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          Material(color: Colors.transparent, child: child),
        ],
      ),
    );
  }

  Widget _buildTagsField(bool isDark) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Add Tag',
                  hintText: 'e.g. Traditional, Alphabet',
                ),
                onFieldSubmitted: (val) {
                  _addTag(val);
                  controller.clear();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: Color(0xFF10B981)),
              onPressed: () {
                _addTag(controller.text);
                controller.clear();
              },
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => _removeTag(tag),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBlockSubtitle(ContentBlock block) {
    switch (block.type) {
      case 'text':
        final t = block as TextBlock;
        return Text(
          t.markdown.isNotEmpty ? t.markdown : 'Empty markup text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case 'image':
        final i = block as ImageBlock;
        return Text(i.media.url.isNotEmpty ? i.media.url : 'No image uploaded');
      case 'video':
        final v = block as VideoBlock;
        return Text(v.media.url.isNotEmpty ? v.media.url : 'No video uploaded');
      case 'audio':
        final a = block as AudioBlock;
        return Text(a.media.url.isNotEmpty ? a.media.url : 'No audio uploaded');
      case 'lottie':
        final l = block as LottieBlock;
        return Text(
          l.media.url.isNotEmpty ? l.media.url : 'No Lottie JSON uploaded',
        );
      case 'quiz':
        final q = block as QuizBlock;
        return Text(
          q.quizId.isNotEmpty
              ? 'Quiz Reference ID: ${q.quizId}'
              : 'No quiz selected',
        );
      case 'glyph':
        final g = block as GlyphBlock;
        return Text('Ol Chiki: ${g.olChiki} / Latin: ${g.latin}');
      case 'callout':
        final c = block as CalloutBlock;
        return Text('Callout variant: ${c.variant.name} / ${c.text}');
      case 'tracing':
        final tr = block as TracingBlock;
        return Text(
          'Tracing config for ${tr.config.glyph} with ${tr.config.strokes.length} strokes',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _editBlockInline(BuildContext context, int index) {
    final block = _blocks[index];
    showDialog(
      context: context,
      builder: (context) {
        final textController1 = TextEditingController();
        final textController2 = TextEditingController();
        ContentMedia? blockMedia;
        CalloutVariant calloutVariant = CalloutVariant.note;

        // Pre-fill fields matching block types
        if (block is TextBlock) {
          textController1.text = block.markdown;
        } else if (block is ImageBlock) {
          blockMedia = block.media;
          textController1.text = block.caption ?? '';
        } else if (block is VideoBlock) {
          blockMedia = block.media;
          textController1.text = block.posterUrl ?? '';
        } else if (block is AudioBlock) {
          blockMedia = block.media;
          textController1.text = block.transcript ?? '';
        } else if (block is LottieBlock) {
          blockMedia = block.media;
        } else if (block is QuizBlock) {
          textController1.text = block.quizId;
        } else if (block is GlyphBlock) {
          textController1.text = block.olChiki;
          textController2.text = block.latin;
          blockMedia = block.audioUrl != null
              ? ContentMedia(
                  url: block.audioUrl!,
                  fileId: '',
                  kind: ContentMediaKind.audio,
                )
              : null;
        } else if (block is CalloutBlock) {
          textController1.text = block.text;
          calloutVariant = block.variant;
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${block.type.toUpperCase()} Content Block'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      if (block is TextBlock)
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Markdown / Raw Text',
                          ),
                          maxLines: 8,
                        ),
                      if (block is ImageBlock) ...[
                        MediaPickerField(
                          label: 'Image Asset',
                          kind: ContentMediaKind.image,
                          value: blockMedia,
                          onChanged: (media) =>
                              setDialogState(() => blockMedia = media),
                        ),
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Caption (Optional)',
                          ),
                        ),
                      ],
                      if (block is VideoBlock) ...[
                        MediaPickerField(
                          label: 'Video Clip',
                          kind: ContentMediaKind.video,
                          value: blockMedia,
                          onChanged: (media) =>
                              setDialogState(() => blockMedia = media),
                        ),
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Poster Image Cover URL',
                          ),
                        ),
                      ],
                      if (block is AudioBlock) ...[
                        MediaPickerField(
                          label: 'Audio Pronunciation',
                          kind: ContentMediaKind.audio,
                          value: blockMedia,
                          onChanged: (media) =>
                              setDialogState(() => blockMedia = media),
                        ),
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Transcript text',
                          ),
                          maxLines: 3,
                        ),
                      ],
                      if (block is LottieBlock)
                        MediaPickerField(
                          label: 'Lottie JSON Animation',
                          kind: ContentMediaKind.lottie,
                          value: blockMedia,
                          onChanged: (media) =>
                              setDialogState(() => blockMedia = media),
                        ),
                      if (block is QuizBlock)
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Quiz Reference ID',
                          ),
                        ),
                      if (block is GlyphBlock) ...[
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Ol Chiki Character glyph',
                          ),
                        ),
                        TextField(
                          controller: textController2,
                          decoration: const InputDecoration(
                            labelText: 'Latin pronunciation name',
                          ),
                        ),
                        MediaPickerField(
                          label: 'Audio Pronunciation',
                          kind: ContentMediaKind.audio,
                          value: blockMedia,
                          onChanged: (media) =>
                              setDialogState(() => blockMedia = media),
                        ),
                      ],
                      if (block is CalloutBlock) ...[
                        DropdownButtonFormField<CalloutVariant>(
                          value: calloutVariant,
                          items: CalloutVariant.values.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(v.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setDialogState(() => calloutVariant = v!),
                          decoration: const InputDecoration(
                            labelText: 'Variant',
                          ),
                        ),
                        TextField(
                          controller: textController1,
                          decoration: const InputDecoration(
                            labelText: 'Notice message text',
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Apply specific edits
                      if (block is TextBlock) {
                        _blocks[index] = TextBlock(
                          id: block.id,
                          order: block.order,
                          markdown: textController1.text,
                        );
                      } else if (block is ImageBlock) {
                        _blocks[index] = ImageBlock(
                          id: block.id,
                          order: block.order,
                          media:
                              blockMedia ??
                              const ContentMedia(
                                url: '',
                                fileId: '',
                                kind: ContentMediaKind.image,
                              ),
                          caption: textController1.text.isNotEmpty
                              ? textController1.text
                              : null,
                        );
                      } else if (block is VideoBlock) {
                        _blocks[index] = VideoBlock(
                          id: block.id,
                          order: block.order,
                          media:
                              blockMedia ??
                              const ContentMedia(
                                url: '',
                                fileId: '',
                                kind: ContentMediaKind.video,
                              ),
                          posterUrl: textController1.text.isNotEmpty
                              ? textController1.text
                              : null,
                        );
                      } else if (block is AudioBlock) {
                        _blocks[index] = AudioBlock(
                          id: block.id,
                          order: block.order,
                          media:
                              blockMedia ??
                              const ContentMedia(
                                url: '',
                                fileId: '',
                                kind: ContentMediaKind.audio,
                              ),
                          transcript: textController1.text.isNotEmpty
                              ? textController1.text
                              : null,
                        );
                      } else if (block is LottieBlock) {
                        _blocks[index] = LottieBlock(
                          id: block.id,
                          order: block.order,
                          media:
                              blockMedia ??
                              const ContentMedia(
                                url: '',
                                fileId: '',
                                kind: ContentMediaKind.lottie,
                              ),
                        );
                      } else if (block is QuizBlock) {
                        _blocks[index] = QuizBlock(
                          id: block.id,
                          order: block.order,
                          quizId: textController1.text,
                        );
                      } else if (block is GlyphBlock) {
                        _blocks[index] = GlyphBlock(
                          id: block.id,
                          order: block.order,
                          olChiki: textController1.text,
                          latin: textController2.text,
                          audioUrl: blockMedia?.url,
                        );
                      } else if (block is CalloutBlock) {
                        _blocks[index] = CalloutBlock(
                          id: block.id,
                          order: block.order,
                          text: textController1.text,
                          variant: calloutVariant,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text(
                    'Save Block',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
