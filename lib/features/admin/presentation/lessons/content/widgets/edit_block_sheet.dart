import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../../core/api/ai_service.dart';
import '../../../widgets/admin_form_widgets.dart';
import '../../../widgets/admin_upload_field.dart';

class EditBlockSheet extends ConsumerStatefulWidget {
  final LessonBlockEntity block;
  final ValueChanged<LessonBlockEntity> onUpdate;

  const EditBlockSheet({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  static void show({
    required BuildContext context,
    required LessonBlockEntity block,
    required ValueChanged<LessonBlockEntity> onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBlockSheet(block: block, onUpdate: onUpdate),
    );
  }

  @override
  ConsumerState<EditBlockSheet> createState() => _EditBlockSheetState();
}

class _EditBlockSheetState extends ConsumerState<EditBlockSheet> {
  late final TextEditingController olChikiCtrl;
  late final TextEditingController latinCtrl;
  late final TextEditingController imageCtrl;
  late final TextEditingController audioCtrl;
  late final TextEditingController animationCtrl;
  late final TextEditingController quizRefCtrl;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    olChikiCtrl = TextEditingController(text: block.textOlChiki ?? '');
    latinCtrl = TextEditingController(text: block.textLatin ?? '');
    imageCtrl = TextEditingController(text: block.imageUrl ?? '');
    audioCtrl = TextEditingController(text: block.audioUrl ?? '');
    animationCtrl = TextEditingController(
      text: block.data?['animationUrl'] ?? '',
    );
    quizRefCtrl = TextEditingController(text: block.data?['quizRefId'] ?? '');
  }

  @override
  void dispose() {
    olChikiCtrl.dispose();
    latinCtrl.dispose();
    imageCtrl.dispose();
    audioCtrl.dispose();
    animationCtrl.dispose();
    quizRefCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updatedBlock = LessonBlockEntity(
      type: widget.block.type,
      textOlChiki: olChikiCtrl.text.isEmpty ? null : olChikiCtrl.text,
      textLatin: latinCtrl.text.isEmpty ? null : latinCtrl.text,
      imageUrl: imageCtrl.text.isEmpty ? null : imageCtrl.text,
      audioUrl: audioCtrl.text.isEmpty ? null : audioCtrl.text,
      data: {
        if (animationCtrl.text.isNotEmpty) 'animationUrl': animationCtrl.text,
        if (quizRefCtrl.text.isNotEmpty) 'quizRefId': quizRefCtrl.text,
      },
    );
    widget.onUpdate(updatedBlock);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final block = widget.block;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit ${block.type.toUpperCase()} Block',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                if (block.type == 'text') ...[
                  AdminTextField(
                    controller: olChikiCtrl,
                    label: 'Ol Chiki Text',
                    hint: 'Enter Ol Chiki text',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AdminTextField(
                          controller: latinCtrl,
                          label: 'Latin Text / Meaning',
                          hint: 'Enter translation',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: isTranslating
                            ? null
                            : () async {
                                if (olChikiCtrl.text.trim().isEmpty) return;
                                setState(() => isTranslating = true);
                                try {
                                  final result = await ref
                                      .read(aiServiceProvider)
                                      .translateFromOlChiki(
                                        olChikiCtrl.text.trim(),
                                      );
                                  if (result != null) {
                                    latinCtrl.text = result.translation;
                                  }
                                } finally {
                                  setState(() => isTranslating = false);
                                }
                              },
                        icon: isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 20),
                        tooltip: 'Magic Fill (AI Translate)',
                      ),
                    ],
                  ),
                ],
                if (block.type == 'image') ...[
                  AdminUploadField(
                    controller: imageCtrl,
                    label: 'Image URL',
                    icon: Icons.image_rounded,
                    isDark: isDark,
                    folder: 'lesson-images',
                    uploadType: AdminUploadType.image,
                    dialogSetState: setState,
                  ),
                ],
                if (block.type == 'audio') ...[
                  AdminUploadField(
                    controller: audioCtrl,
                    label: 'Audio URL',
                    icon: Icons.audiotrack_rounded,
                    isDark: isDark,
                    folder: 'lesson-audio',
                    uploadType: AdminUploadType.audio,
                    dialogSetState: setState,
                  ),
                ],
                if (block.type == 'video') ...[
                  AdminUploadField(
                    controller:
                        audioCtrl, // Re-using audioCtrl for video URL storage in model
                    label: 'Video URL',
                    icon: Icons.videocam_rounded,
                    isDark: isDark,
                    folder: 'lesson-video',
                    uploadType: AdminUploadType.video,
                    dialogSetState: setState,
                  ),
                ],
                if (block.type == 'quiz') ...[
                  AdminTextField(
                    controller: quizRefCtrl,
                    label: 'Quiz Reference ID',
                    hint: 'Start typing quiz ID...',
                  ),
                ],
                if (block.type == 'lottie') ...[
                  AdminUploadField(
                    controller: animationCtrl,
                    label: 'Lottie Animation URL',
                    icon: Icons.animation_rounded,
                    isDark: isDark,
                    folder: 'animations',
                    uploadType: AdminUploadType.lottie,
                    dialogSetState: setState,
                  ),
                ],

                if (block.type == 'image' ||
                    block.type == 'audio' ||
                    block.type == 'video' ||
                    block.type == 'lottie') ...[
                  const SizedBox(height: 16),
                  AdminTextField(
                    controller: latinCtrl,
                    label: 'Caption / Label',
                    hint: 'Enter a label',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update Block',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}
