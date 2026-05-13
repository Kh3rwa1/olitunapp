import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../lessons/presentation/providers/lesson_notifier.dart';
import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../core/presentation/animations/scale_button.dart';
import 'widgets/lesson_block_card.dart';
import 'widgets/add_block_sheet.dart';
import 'widgets/edit_block_sheet.dart';

class AdminLessonContentScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const AdminLessonContentScreen({super.key, required this.lessonId});

  @override
  ConsumerState<AdminLessonContentScreen> createState() =>
      _AdminLessonContentScreenState();
}

class _AdminLessonContentScreenState
    extends ConsumerState<AdminLessonContentScreen> {
  late List<LessonBlockEntity> _blocks;
  bool _isLoading = true;
  bool _hasChanges = false;
  LessonEntity? _lesson;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final lessons = ref.read(lessonNotifierProvider).value ?? [];
    try {
      _lesson = lessons.firstWhere((l) => l.id == widget.lessonId);
      _blocks = List.from(_lesson!.blocks);
      setState(() => _isLoading = false);
    } catch (e) {
      context.pop();
    }
  }

  Future<void> _saveChanges() async {
    if (_lesson == null) return;

    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A lesson must have at least one block!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    EditBlockSheet.show(
      context: context,
      block: _blocks.last,
      onUpdate: (updatedBlock) =>
          _updateBlock(_blocks.length - 1, updatedBlock),
    );
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
            Text('Manage Content', style: AdminTokens.cardTitle(isDark)),
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
            key: ValueKey('block_${block.hashCode}_$index'),
            margin: const EdgeInsets.only(bottom: 16),
            child: LessonBlockCard(
              index: index,
              block: block,
              isDark: isDark,
              onEdit: () => EditBlockSheet.show(
                context: context,
                block: block,
                onUpdate: (updatedBlock) => _updateBlock(index, updatedBlock),
              ),
              onDelete: () => _removeBlock(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddBlockSheet.show(context, _addBlock),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Block',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
