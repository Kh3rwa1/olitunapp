import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_form_widgets.dart';
import '../../lessons/presentation/providers/lesson_notifier.dart';
import '../../../core/storage/upload_service.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import '../../../shared/widgets/gamified_card.dart';
import '../../../core/presentation/animations/scale_button.dart';
import '../../../core/api/ai_service.dart';

class AdminLessonContentScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const AdminLessonContentScreen({super.key, required this.lessonId});

  @override
  ConsumerState<AdminLessonContentScreen> createState() =>
      _AdminLessonContentScreenState();
}

class _AdminLessonContentScreenState
    extends ConsumerState<AdminLessonContentScreen> {
  // Local list to manage state before saving
  late List<LessonBlockEntity> _blocks;
  bool _isLoading = true;
  bool _hasChanges = false;
  LessonEntity? _lesson;

  @override
  void initState() {
    super.initState();
    // Load lesson data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
    try {
      _lesson = lessons.firstWhere((l) => l.id == widget.lessonId);
      _blocks = List.from(_lesson!.blocks);
      setState(() => _isLoading = false);
    } catch (e) {
      // Lesson not found
      context.pop();
    }
  }

  Future<void> _saveChanges() async {
    if (_lesson == null) return;

    final updatedLesson = _lesson!.copyWith(blocks: _blocks);
    await ref.read(lessonNotifierProvider.notifier).updateLesson(updatedLesson);

    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully!')),
      );
    }
  }

  void _addBlock(String type) {
    setState(() {
      _blocks.add(LessonBlockEntity(type: type));
      _hasChanges = true;
    });
    // Scroll to bottom -> handled by list view naturally or we can force
    _editBlock(_blocks.length - 1);
  }

  void _updateBlock(int index, LessonBlockEntity block) {
    setState(() {
      _blocks[index] = block;
      _hasChanges = true;
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      _hasChanges = true;
    });
  }

  void _moveBlock(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Content',
              style: AdminTokens.cardTitle(isDark),
            ),
            Text(
              _lesson?.titleLatin ?? 'Lesson Content',
              style: AdminTokens.label(isDark),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AdminTokens.textPrimary(isDark)),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ScaleButton(
                onPressed: _saveChanges,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.save_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _blocks.length,
        onReorder: _moveBlock,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 8,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final block = _blocks[index];
          return Container(
            key: ValueKey('block_$index'), // Unique key for reordering
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildBlockCard(index, block, isDark),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBlockDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Block',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBlockCard(int index, LessonBlockEntity block, bool isDark) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (block.type) {
      case 'text':
        icon = Icons.text_fields_rounded;
        color = Colors.blue;
        title = 'Text Block';
        subtitle = block.textLatin ?? block.textOlChiki ?? 'Empty text block';
        break;
      case 'image':
        icon = Icons.image_rounded;
        color = AppColors.duoBlue;
        title = 'Image Block';
        subtitle = block.imageUrl ?? 'No image selected';
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        color = Colors.orange;
        title = 'Audio Block';
        subtitle = block.audioUrl ?? 'No audio selected';
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        color = Colors.purple;
        title = 'Video Block';
        subtitle = block.audioUrl ?? 'No video selected';
        break;
      case 'lottie':
        icon = Icons.animation_rounded;
        color = const Color(0xFF10B981);
        title = 'Lottie Animation';
        subtitle = block.data?['animationUrl'] ?? 'No animation selected';
        break;
      case 'quiz':
        icon = Icons.quiz_rounded;
        color = Colors.green;
        title = 'Quiz Block';
        subtitle = 'Quiz Ref: ${block.data?['quizRefId'] ?? "None"}';
        break;
      default:
        icon = Icons.extension;
        color = Colors.grey;
        title = 'Unknown Block';
        subtitle = block.type;
    }

    return GamifiedCard(
      borderRadius: AdminTokens.radiusLg,
      color: AdminTokens.raised(isDark),
      padding: const EdgeInsets.all(0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: isDark ? Colors.white70 : Colors.black54,
              onPressed: () => _editBlock(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Colors.red[400],
              onPressed: () => _removeBlock(index),
            ),
            Icon(
              Icons.drag_handle_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBlockDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AdminTokens.overlay(isDark),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AdminTokens.radius2xl),
            ),
            boxShadow: AdminTokens.overlayShadow(isDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Block Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTypeOption(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('text');
                    },
                  ),
                  _buildTypeOption(
                    icon: Icons.image_rounded,
                    label: 'Image',
                    color: AppColors.duoBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('image');
                    },
                  ),
                  _buildTypeOption(
                    icon: Icons.audiotrack_rounded,
                    label: 'Audio',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('audio');
                    },
                  ),
                  _buildTypeOption(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('video');
                    },
                  ),
                  _buildTypeOption(
                    icon: Icons.quiz_rounded,
                    label: 'Quiz',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('quiz');
                    },
                  ),
                  _buildTypeOption(
                    icon: Icons.animation_rounded,
                    label: 'Lottie',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('lottie');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _editBlock(int index) {
    final block = _blocks[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final olChikiCtrl = TextEditingController(text: block.textOlChiki ?? '');
    final latinCtrl = TextEditingController(text: block.textLatin ?? '');
    bool isTranslating = false;
    final imageCtrl = TextEditingController(text: block.imageUrl ?? '');
    final audioCtrl = TextEditingController(text: block.audioUrl ?? '');
    final animationCtrl = TextEditingController(text: block.data?['animationUrl'] ?? '');
    final quizRefCtrl = TextEditingController(text: block.data?['quizRefId'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      _buildTextField(
                        olChikiCtrl,
                        'Ol Chiki Text',
                        'Enter Ol Chiki text',
                        isDark,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              latinCtrl,
                              'Latin Text / Meaning',
                              'Enter translation',
                              isDark,
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatefulBuilder(
                            builder: (context, setBtnState) {
                              return IconButton.filledTonal(
                                onPressed: isTranslating
                                    ? null
                                    : () async {
                                        if (olChikiCtrl.text.trim().isEmpty) {
                                          return;
                                        }
                                        setBtnState(() => isTranslating = true);
                                        try {
                                          final result = await ref
                                              .read(aiServiceProvider)
                                              .translateFromOlChiki(
                                                olChikiCtrl.text.trim(),
                                                to: 'en',
                                              );
                                          if (result != null) {
                                            latinCtrl.text = result.translation;
                                          }
                                        } finally {
                                          setBtnState(
                                            () => isTranslating = false,
                                          );
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
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    if (block.type == 'image') ...[
                      _buildUploadField(
                        controller: imageCtrl,
                        label: 'Image URL',
                        icon: Icons.image_rounded,
                        isDark: isDark,
                        onUpload: () =>
                            _pickAndUpload(context, imageCtrl, 'lesson-images'),
                      ),
                    ],
                    if (block.type == 'audio') ...[
                      _buildUploadField(
                        controller: audioCtrl,
                        label: 'Audio URL',
                        icon: Icons.audiotrack_rounded,
                        isDark: isDark,
                        onUpload: () =>
                            _pickAndUpload(context, audioCtrl, 'lesson-audio'),
                      ),
                    ],
                    if (block.type == 'video') ...[
                      _buildUploadField(
                        controller:
                            audioCtrl, // Re-using audioCtrl for video URL storage in model
                        label: 'Video URL',
                        icon: Icons.videocam_rounded,
                        isDark: isDark,
                        onUpload: () =>
                            _pickAndUpload(context, audioCtrl, 'lesson-video'),
                      ),
                    ],
                    if (block.type == 'quiz') ...[
                      _buildTextField(
                        quizRefCtrl,
                        'Quiz Reference ID',
                        'Start typing quiz ID...',
                        isDark,
                      ),
                    ],
                    if (block.type == 'lottie') ...[
                      _buildUploadField(
                        controller: animationCtrl,
                        label: 'Lottie Animation URL',
                        icon: Icons.animation_rounded,
                        isDark: isDark,
                        onUpload: () => _pickAndUploadLottie(
                          context,
                          animationCtrl,
                          'animations',
                        ),
                      ),
                    ],

                    if (block.type == 'image' ||
                        block.type == 'audio' ||
                        block.type == 'video' ||
                        block.type == 'lottie') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        latinCtrl,
                        'Caption / Label',
                        'Enter a label',
                        isDark,
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
                  onPressed: () {
                    final updatedBlock = LessonBlockEntity(
                      type: block.type,
                      textOlChiki: olChikiCtrl.text.isEmpty
                          ? null
                          : olChikiCtrl.text,
                      textLatin: latinCtrl.text.isEmpty ? null : latinCtrl.text,
                      imageUrl: imageCtrl.text.isEmpty ? null : imageCtrl.text,
                      audioUrl: audioCtrl.text.isEmpty ? null : audioCtrl.text,
                      data: {
                        if (animationCtrl.text.isNotEmpty)
                          'animationUrl': animationCtrl.text,
                        if (quizRefCtrl.text.isNotEmpty)
                          'quizRefId': quizRefCtrl.text,
                      },
                    );
                    _updateBlock(index, updatedBlock);
                    Navigator.pop(context);
                  },
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
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    bool isDark, {
    int maxLines = 1,
  }) {
    return AdminTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
    );
  }

  Widget _buildUploadField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTokens.label(isDark)),
        const SizedBox(height: AdminTokens.space2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AdminTokens.bodyStrong(isDark),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: AdminTokens.body(isDark).copyWith(
                    color: AdminTokens.textTertiary(isDark),
                  ),
                  filled: true,
                  fillColor: AdminTokens.sunken(isDark),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: BorderSide(color: AdminTokens.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: const BorderSide(
                      color: AdminTokens.accent,
                      width: 1.5,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    borderSide: BorderSide(color: AdminTokens.border(isDark)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onUpload,
              icon: Icon(icon, size: 20),
              tooltip: 'Upload File',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    TextEditingController controller,
    String folder,
  ) async {
    try {
      final fileType = folder.contains('audio')
          ? FileType.audio
          : (folder.contains('video') ? FileType.video : FileType.image);

      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: fileType,
      );

      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(result.files.first, folder);
        if (url != null) {
          setState(() {
            controller.text = url;
            _hasChanges = true;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _pickAndUploadLottie(
    BuildContext context,
    TextEditingController controller,
    String folder,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(uploadServiceProvider)
            .uploadMedia(result.files.first, folder);
        if (url != null) {
          setState(() {
            controller.text = url;
            _hasChanges = true;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lottie animation uploaded!')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }
}
