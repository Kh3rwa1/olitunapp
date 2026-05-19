import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isSaving = false;
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
      context.go('/admin/lessons');
    }
  }

  Future<void> _saveChanges() async {
    if (_lesson == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedLesson = _lesson!.copyWith(blocks: _blocks);
      await ref
          .read(lessonNotifierProvider.notifier)
          .updateLesson(updatedLesson);

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Content saved successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    final block = _blocks[index];
    setState(() {
      _blocks.removeAt(index);
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${block.type} block'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _blocks.insert(index, block);
              _hasChanges = true;
            });
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    final isWide = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Top Bar with breadcrumb, title, and save
          _buildTopBar(isDark, isWide),

          // Lesson summary card
          _buildLessonSummary(isDark, isWide),

          // Block list
          Expanded(
            child: _blocks.isEmpty
                ? _buildEmptyBlocksState(isDark)
                : ReorderableListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 32 : 16,
                      12,
                      isWide ? 32 : 16,
                      100,
                    ),
                    itemCount: _blocks.length,
                    // ignore: deprecated_member_use
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
                        margin: const EdgeInsets.only(bottom: 12),
                        child: LessonBlockCard(
                          index: index,
                          block: block,
                          isDark: isDark,
                          onEdit: () => EditBlockSheet.show(
                            context: context,
                            block: block,
                            onUpdate: (updatedBlock) =>
                                _updateBlock(index, updatedBlock),
                          ),
                          onDelete: () => _removeBlock(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddBlockSheet.show(context, _addBlock),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Block',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isWide ? 32 : 16,
        isWide ? 28 : 16,
        isWide ? 32 : 16,
        16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/admin/lessons'),
                  child: const Text(
                    'Lessons',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                Expanded(
                  child: Text(
                    _lesson?.titleLatin ?? 'Content',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title + Back + Save
            Row(
              children: [
                ScaleButton(
                  onPressed: () => context.go('/admin/lessons'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Content',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Drag blocks to reorder • Tap to edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasChanges)
                  ScaleButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.save_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                if (!_hasChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Saved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonSummary(bool isDark, bool isWide) {
    final blockTypes = <String, int>{};
    for (final b in _blocks) {
      blockTypes[b.type] = (blockTypes[b.type] ?? 0) + 1;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(isWide ? 32 : 16, 12, isWide ? 32 : 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark
                ? Colors.white30
                : AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black45,
                ),
                children: [
                  TextSpan(
                    text:
                        '${_blocks.length} block${_blocks.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  if (blockTypes.isNotEmpty) ...[
                    const TextSpan(text: '  •  '),
                    TextSpan(
                      text: blockTypes.entries
                          .map((e) => '${e.value} ${e.key}')
                          .join(', '),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBlocksState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No content blocks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Block" below to start building\nyour lesson content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => AddBlockSheet.show(context, _addBlock),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add Your First Block',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
