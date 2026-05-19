import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../../core/api/ai_service.dart';
import '../../../widgets/admin_form_widgets.dart';

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
  late final TextEditingController quizRefCtrl;
  String? _imageUrl;
  String? _audioUrl;
  String? _animationUrl;
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    olChikiCtrl = TextEditingController(text: block.textOlChiki ?? '');
    latinCtrl = TextEditingController(text: block.textLatin ?? '');
    _imageUrl = block.imageUrl;
    _audioUrl = block.audioUrl;
    _animationUrl = block.data?['animationUrl'];
    quizRefCtrl = TextEditingController(text: block.data?['quizRefId'] ?? '');
  }

  @override
  void dispose() {
    olChikiCtrl.dispose();
    latinCtrl.dispose();
    quizRefCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updatedBlock = LessonBlockEntity(
      type: widget.block.type,
      textOlChiki: olChikiCtrl.text.isEmpty ? null : olChikiCtrl.text,
      textLatin: latinCtrl.text.isEmpty ? null : latinCtrl.text,
      imageUrl: _imageUrl != null && _imageUrl!.isNotEmpty ? _imageUrl : null,
      audioUrl: _audioUrl != null && _audioUrl!.isNotEmpty ? _audioUrl : null,
      data: {
        if (_animationUrl != null && _animationUrl!.isNotEmpty)
          'animationUrl': _animationUrl,
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

    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (block.type) {
      case 'text':
        icon = Icons.text_fields_rounded;
        iconColor = Colors.blue;
        typeLabel = 'Text Block';
        break;
      case 'image':
        icon = Icons.image_rounded;
        iconColor = AppColors.duoBlue;
        typeLabel = 'Image Block';
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        iconColor = Colors.orange;
        typeLabel = 'Audio Block';
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        iconColor = Colors.purple;
        typeLabel = 'Video Block';
        break;
      case 'lottie':
        icon = Icons.animation_rounded;
        iconColor = const Color(0xFF10B981);
        typeLabel = 'Lottie Animation';
        break;
      case 'quiz':
        icon = Icons.quiz_rounded;
        iconColor = Colors.green;
        typeLabel = 'Quiz Block';
        break;
      default:
        icon = Icons.extension;
        iconColor = Colors.grey;
        typeLabel = 'Content Block';
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit $typeLabel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Modify this block\'s details & presentation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20,
                                ),
                          tooltip: 'Magic Fill (AI Translate)',
                        ),
                      ],
                    ),
                  ],
                  if (block.type == 'image') ...[
                    AdminMediaField(
                      label: 'Image',
                      icon: Icons.image_rounded,
                      accent: AppColors.primary,
                      currentUrl: _imageUrl,
                      uploadFolder: 'lesson-images',
                      fileType: FileType.image,
                      onUploaded: (url) => setState(() => _imageUrl = url),
                      previewBuilder: (url) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (block.type == 'audio') ...[
                    AdminMediaField(
                      label: 'Audio',
                      icon: Icons.audiotrack_rounded,
                      accent: const Color(0xFF10B981),
                      currentUrl: _audioUrl,
                      uploadFolder: 'lesson-audio',
                      fileType: FileType.audio,
                      onUploaded: (url) => setState(() => _audioUrl = url),
                    ),
                  ],
                  if (block.type == 'video') ...[
                    AdminMediaField(
                      label: 'Video',
                      icon: Icons.videocam_rounded,
                      accent: const Color(0xFFF59E0B),
                      currentUrl:
                          _audioUrl, // Re-using _audioUrl for video URL storage in model
                      uploadFolder: 'lesson-video',
                      fileType: FileType.video,
                      onUploaded: (url) => setState(() => _audioUrl = url),
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
                    AdminMediaField(
                      label: 'Lottie Animation',
                      icon: Icons.animation_rounded,
                      accent: const Color(0xFF6366F1),
                      currentUrl: _animationUrl,
                      uploadFolder: 'animations',
                      fileType: FileType.custom,
                      allowedExtensions: const ['json'],
                      onUploaded: (url) => setState(() => _animationUrl = url),
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
          ),

          const Divider(height: 1),

          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
