import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/gamified_card.dart';
import '../../../core/presentation/animations/scale_button.dart';

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
  late List<LessonBlock> _blocks;
  bool _isLoading = true;
  bool _hasChanges = false;
  LessonModel? _lesson;

  @override
  void initState() {
    super.initState();
    // Load lesson data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final lessons = ref.read(lessonsProvider).value ?? [];
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
    await ref.read(lessonsProvider.notifier).updateLesson(updatedLesson);

    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully!')),
      );
    }
  }

  void _addBlock(String type) {
    setState(() {
      _blocks.add(LessonBlock(type: type));
      _hasChanges = true;
    });
    // Scroll to bottom -> handled by list view naturally or we can force
    _editBlock(_blocks.length - 1);
  }

  void _updateBlock(int index, LessonBlock block) {
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
        backgroundColor: isDark
            ? AppColors.darkBackground
            : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Content',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              _lesson?.titleLatin ?? 'Lesson Content',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
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
                        color: AppColors.primary.withOpacity(0.3),
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

  Widget _buildBlockCard(int index, LessonBlock block, bool isDark) {
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
      case 'quiz':
        icon = Icons.quiz_rounded;
        color = Colors.green;
        title = 'Quiz Block';
        subtitle = 'Quiz Ref: ${block.quizRefId ?? "None"}';
        break;
      default:
        icon = Icons.extension;
        color = Colors.grey;
        title = 'Unknown Block';
        subtitle = block.type;
    }

    return GamifiedCard(
      borderRadius: 16,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.all(0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    icon: Icons.quiz_rounded,
                    label: 'Quiz',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _addBlock('quiz');
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
              color: color.withOpacity(0.1),
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
    final imageCtrl = TextEditingController(text: block.imageUrl ?? '');
    final audioCtrl = TextEditingController(text: block.audioUrl ?? '');
    final quizRefCtrl = TextEditingController(text: block.quizRefId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      _buildTextField(
                        latinCtrl,
                        'Latin Text / Meaning',
                        'Enter translation',
                        isDark,
                        maxLines: 3,
                      ),
                    ],
                    if (block.type == 'image') ...[
                      _buildTextField(
                        imageCtrl,
                        'Image URL',
                        'https://example.com/image.png',
                        isDark,
                      ),
                    ],
                    if (block.type == 'audio') ...[
                      _buildTextField(
                        audioCtrl,
                        'Audio URL',
                        'https://example.com/audio.mp3',
                        isDark,
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

                    if (block.type == 'image' || block.type == 'audio') ...[
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
                    final updatedBlock = LessonBlock(
                      type: block.type,
                      textOlChiki: olChikiCtrl.text.isEmpty
                          ? null
                          : olChikiCtrl.text,
                      textLatin: latinCtrl.text.isEmpty ? null : latinCtrl.text,
                      imageUrl: imageCtrl.text.isEmpty ? null : imageCtrl.text,
                      audioUrl: audioCtrl.text.isEmpty ? null : audioCtrl.text,
                      quizRefId: quizRefCtrl.text.isEmpty
                          ? null
                          : quizRefCtrl.text,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
