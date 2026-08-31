import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:itun/shared/models/content_item.dart';
import 'content_block_edit_dialog.dart';
import 'content_form_card.dart';

class ContentBlockListSection extends StatelessWidget {
  final bool isDark;
  final List<ContentBlock> blocks;
  final String glyphValue;
  final ValueChanged<ContentBlock> onAddBlock;
  final ValueChanged<int> onRemoveBlock;
  final void Function(int oldIndex, int newIndex) onReorderBlocks;
  final void Function(int index, ContentBlock block) onUpdateBlock;
  final ValueChanged<String> onMarkForDeletion;

  const ContentBlockListSection({
    super.key,
    required this.isDark,
    required this.blocks,
    required this.glyphValue,
    required this.onAddBlock,
    required this.onRemoveBlock,
    required this.onReorderBlocks,
    required this.onUpdateBlock,
    required this.onMarkForDeletion,
  });

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
                    onAddBlock(
                      TextBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
                        markdown: '',
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.image_rounded, 'Image', () {
                    onAddBlock(
                      ImageBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
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
                      onAddBlock(
                        VideoBlock(
                          id: const Uuid().v4(),
                          order: blocks.length,
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
                    onAddBlock(
                      AudioBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
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
                    onAddBlock(
                      LottieBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
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
                    onAddBlock(
                      QuizBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
                        quizId: '',
                      ),
                    );
                    Navigator.pop(context);
                  }),
                  _buildBlockTypeButton(Icons.abc_rounded, 'Glyph', () {
                    onAddBlock(
                      GlyphBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
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
                      onAddBlock(
                        CalloutBlock(
                          id: const Uuid().v4(),
                          order: blocks.length,
                          text: '',
                          variant: CalloutVariant.note,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildBlockTypeButton(Icons.gesture_rounded, 'Tracing', () {
                    onAddBlock(
                      TracingBlock(
                        id: const Uuid().v4(),
                        order: blocks.length,
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
          color: Colors.black.withValues(alpha: 0.04),
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

  @override
  Widget build(BuildContext context) {
    return ContentFormCard(
      isDark: isDark,
      title: 'Rich Multimedia Blocks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blocks.isEmpty)
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
                // ignore: deprecated_member_use
                onReorder: onReorderBlocks,
                children: [
                  for (int i = 0; i < blocks.length; i++)
                    ListTile(
                      key: Key(blocks[i].id),
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.12),
                        foregroundColor: const Color(0xFF10B981),
                        child: Text('${i + 1}'),
                      ),
                      title: Text(
                        blocks[i].type.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: _buildBlockSubtitle(blocks[i]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () => onRemoveBlock(i),
                          ),
                        ],
                      ),
                      onTap: () {
                        ContentBlockEditDialog.show(
                          context: context,
                          block: blocks[i],
                          onSave: (updated) => onUpdateBlock(i, updated),
                          onMarkForDeletion: onMarkForDeletion,
                        );
                      },
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
    );
  }
}
