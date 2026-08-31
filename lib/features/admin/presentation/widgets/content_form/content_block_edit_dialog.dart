import 'package:flutter/material.dart';

import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/shared/models/content_item.dart';

/// Inline dialog to edit a ContentBlock. MediaPickerField delegates removals to [onMarkForDeletion].
class ContentBlockEditDialog extends StatefulWidget {
  final ContentBlock block;
  final ValueChanged<ContentBlock> onSave;
  final ValueChanged<String> onMarkForDeletion;

  const ContentBlockEditDialog({
    super.key,
    required this.block,
    required this.onSave,
    required this.onMarkForDeletion,
  });

  static Future<void> show({
    required BuildContext context,
    required ContentBlock block,
    required ValueChanged<ContentBlock> onSave,
    required ValueChanged<String> onMarkForDeletion,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ContentBlockEditDialog(
        block: block,
        onSave: onSave,
        onMarkForDeletion: onMarkForDeletion,
      ),
    );
  }

  @override
  State<ContentBlockEditDialog> createState() => _ContentBlockEditDialogState();
}

class _ContentBlockEditDialogState extends State<ContentBlockEditDialog> {
  late final TextEditingController _textController1;
  late final TextEditingController _textController2;
  ContentMedia? _blockMedia;
  CalloutVariant _calloutVariant = CalloutVariant.note;

  @override
  void initState() {
    super.initState();
    _textController1 = TextEditingController();
    _textController2 = TextEditingController();

    final block = widget.block;
    if (block is TextBlock) {
      _textController1.text = block.markdown;
    } else if (block is ImageBlock) {
      _blockMedia = block.media;
      _textController1.text = block.caption ?? '';
    } else if (block is VideoBlock) {
      _blockMedia = block.media;
      _textController1.text = block.posterUrl ?? '';
    } else if (block is AudioBlock) {
      _blockMedia = block.media;
      _textController1.text = block.transcript ?? '';
    } else if (block is LottieBlock) {
      _blockMedia = block.media;
    } else if (block is QuizBlock) {
      _textController1.text = block.quizId;
    } else if (block is GlyphBlock) {
      _textController1.text = block.olChiki;
      _textController2.text = block.latin;
      _blockMedia = block.audioUrl != null
          ? ContentMedia(
              url: block.audioUrl!,
              fileId: '',
              kind: ContentMediaKind.audio,
            )
          : null;
    } else if (block is CalloutBlock) {
      _textController1.text = block.text;
      _calloutVariant = block.variant;
    }
  }

  @override
  void dispose() {
    _textController1.dispose();
    _textController2.dispose();
    super.dispose();
  }

  void _save() {
    final block = widget.block;
    ContentBlock updatedBlock = block;

    if (block is TextBlock) {
      updatedBlock = TextBlock(
        id: block.id,
        order: block.order,
        markdown: _textController1.text,
      );
    } else if (block is ImageBlock) {
      updatedBlock = ImageBlock(
        id: block.id,
        order: block.order,
        media:
            _blockMedia ??
            const ContentMedia(
              url: '',
              fileId: '',
              kind: ContentMediaKind.image,
            ),
        caption: _textController1.text.isNotEmpty
            ? _textController1.text
            : null,
      );
    } else if (block is VideoBlock) {
      updatedBlock = VideoBlock(
        id: block.id,
        order: block.order,
        media:
            _blockMedia ??
            const ContentMedia(
              url: '',
              fileId: '',
              kind: ContentMediaKind.video,
            ),
        posterUrl: _textController1.text.isNotEmpty
            ? _textController1.text
            : null,
      );
    } else if (block is AudioBlock) {
      updatedBlock = AudioBlock(
        id: block.id,
        order: block.order,
        media:
            _blockMedia ??
            const ContentMedia(
              url: '',
              fileId: '',
              kind: ContentMediaKind.audio,
            ),
        transcript: _textController1.text.isNotEmpty
            ? _textController1.text
            : null,
      );
    } else if (block is LottieBlock) {
      updatedBlock = LottieBlock(
        id: block.id,
        order: block.order,
        media:
            _blockMedia ??
            const ContentMedia(
              url: '',
              fileId: '',
              kind: ContentMediaKind.lottie,
            ),
      );
    } else if (block is QuizBlock) {
      updatedBlock = QuizBlock(
        id: block.id,
        order: block.order,
        quizId: _textController1.text,
      );
    } else if (block is GlyphBlock) {
      updatedBlock = GlyphBlock(
        id: block.id,
        order: block.order,
        olChiki: _textController1.text,
        latin: _textController2.text,
        audioUrl: _blockMedia?.url,
      );
    } else if (block is CalloutBlock) {
      updatedBlock = CalloutBlock(
        id: block.id,
        order: block.order,
        text: _textController1.text,
        variant: _calloutVariant,
      );
    }

    widget.onSave(updatedBlock);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    return AlertDialog(
      title: Text('Edit ${block.type.toUpperCase()} Content Block'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              if (block is TextBlock)
                TextField(
                  controller: _textController1,
                  decoration: const InputDecoration(
                    labelText: 'Markdown / Raw Text',
                  ),
                  maxLines: 8,
                ),
              if (block is ImageBlock) ...[
                MediaPickerField(
                  label: 'Image Asset',
                  kind: ContentMediaKind.image,
                  value: _blockMedia,
                  onRemove: widget.onMarkForDeletion,
                  onChanged: (media) => setState(() => _blockMedia = media),
                ),
                TextField(
                  controller: _textController1,
                  decoration: const InputDecoration(
                    labelText: 'Caption (Optional)',
                  ),
                ),
              ],
              if (block is VideoBlock) ...[
                MediaPickerField(
                  label: 'Video Clip',
                  kind: ContentMediaKind.video,
                  value: _blockMedia,
                  onRemove: widget.onMarkForDeletion,
                  onChanged: (media) => setState(() => _blockMedia = media),
                ),
                TextField(
                  controller: _textController1,
                  decoration: const InputDecoration(
                    labelText: 'Poster Image Cover URL',
                  ),
                ),
              ],
              if (block is AudioBlock) ...[
                MediaPickerField(
                  label: 'Audio Pronunciation',
                  kind: ContentMediaKind.audio,
                  value: _blockMedia,
                  onRemove: widget.onMarkForDeletion,
                  onChanged: (media) => setState(() => _blockMedia = media),
                ),
                TextField(
                  controller: _textController1,
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
                  value: _blockMedia,
                  onRemove: widget.onMarkForDeletion,
                  onChanged: (media) => setState(() => _blockMedia = media),
                ),
              if (block is QuizBlock)
                TextField(
                  controller: _textController1,
                  decoration: const InputDecoration(
                    labelText: 'Quiz Reference ID',
                  ),
                ),
              if (block is GlyphBlock) ...[
                TextField(
                  controller: _textController1,
                  decoration: const InputDecoration(
                    labelText: 'Ol Chiki Character glyph',
                  ),
                ),
                TextField(
                  controller: _textController2,
                  decoration: const InputDecoration(
                    labelText: 'Latin pronunciation name',
                  ),
                ),
                MediaPickerField(
                  label: 'Audio Pronunciation',
                  kind: ContentMediaKind.audio,
                  value: _blockMedia,
                  onRemove: widget.onMarkForDeletion,
                  onChanged: (media) => setState(() => _blockMedia = media),
                ),
              ],
              if (block is CalloutBlock) ...[
                DropdownButtonFormField<CalloutVariant>(
                  initialValue: _calloutVariant,
                  items: CalloutVariant.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(v.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _calloutVariant = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Variant'),
                ),
                TextField(
                  controller: _textController1,
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
          onPressed: _save,
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
  }
}
