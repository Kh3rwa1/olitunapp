import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../lessons/presentation/providers/lesson_notifier.dart';
import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../lessons/presentation/widgets/dynamic_block_builder.dart';
import 'controllers/block_reorder_controller.dart';
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

  late ScrollController _leftScrollController;
  late ScrollController _previewScrollController;
  int? _hoveredOrFocusedIndex;

  @override
  void initState() {
    super.initState();
    _leftScrollController = ScrollController();
    _previewScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _syncScroll(int index, bool fromLeftToRight) {
    if (fromLeftToRight) {
      if (_previewScrollController.hasClients) {
        // Average mockup preview block height + margins is ~160.0
        final targetOffset = index * 160.0;
        _previewScrollController.animateTo(
          targetOffset.clamp(
            0.0,
            _previewScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      if (_leftScrollController.hasClients) {
        // Average editor card height + margins is ~140.0
        final targetOffset = index * 140.0;
        _leftScrollController.animateTo(
          targetOffset.clamp(
            0.0,
            _leftScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
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
    final draftBlock = LessonBlockEntity(type: type);
    EditBlockSheet.show(
      context: context,
      block: draftBlock,
      onUpdate: (updatedBlock) {
        setState(() {
          _blocks.add(updatedBlock);
          _hasChanges = true;
          _hoveredOrFocusedIndex = _blocks.length - 1;
        });
      },
    );
  }

  void _editBlock(int index, LessonBlockEntity block) {
    setState(() => _hoveredOrFocusedIndex = index);
    EditBlockSheet.show(
      context: context,
      block: block,
      onUpdate: (updatedBlock) => _updateBlock(index, updatedBlock),
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
    setState(() {
      _blocks = reorderLessonBlocks(_blocks, oldIndex, newIndex);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 1024;

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

          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Block Editor (60% width)
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            // Lesson summary card
                            _buildLessonSummary(isDark, isWide),

                            // Block list
                            Expanded(
                              child: _blocks.isEmpty
                                  ? _buildEmptyBlocksState(isDark)
                                  : ReorderableListView.builder(
                                      scrollController: _leftScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        32,
                                        12,
                                        32,
                                        100,
                                      ),
                                      itemCount: _blocks.length,
                                      buildDefaultDragHandles: false,
                                      // ignore: deprecated_member_use
                                      onReorder: _moveBlock,
                                      proxyDecorator:
                                          (child, index, animation) {
                                            return Material(
                                              elevation: 8,
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: child,
                                            );
                                          },
                                      itemBuilder: (context, index) {
                                        final block = _blocks[index];
                                        final isHighlighted =
                                            index == _hoveredOrFocusedIndex;
                                        return Container(
                                          key: ValueKey(
                                            'block_${block.hashCode}_$index',
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: isHighlighted
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF2ECC71,
                                                      ).withValues(alpha: 0.35),
                                                      blurRadius: 16,
                                                      spreadRadius: 2,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              _syncScroll(index, true);
                                              _editBlock(index, block);
                                            },
                                            child: LessonBlockCard(
                                              index: index,
                                              block: block,
                                              isDark: isDark,
                                              onEdit: () =>
                                                  _editBlock(index, block),
                                              onDelete: () =>
                                                  _removeBlock(index),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // Divider line
                      Container(
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      // Right Column: Mockup Live Preview (40% width)
                      Expanded(flex: 4, child: _buildMockupPreview(isDark)),
                    ],
                  )
                : Column(
                    children: [
                      // Lesson summary card
                      _buildLessonSummary(isDark, isWide),

                      // Block list
                      Expanded(
                        child: _blocks.isEmpty
                            ? _buildEmptyBlocksState(isDark)
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  100,
                                ),
                                itemCount: _blocks.length,
                                buildDefaultDragHandles: false,
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
                                    key: ValueKey(
                                      'block_${block.hashCode}_$index',
                                    ),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onTap: () => _editBlock(index, block),
                                      child: LessonBlockCard(
                                        index: index,
                                        block: block,
                                        isDark: isDark,
                                        onEdit: () => _editBlock(index, block),
                                        onDelete: () => _removeBlock(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
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

  Widget _buildMockupPreview(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      alignment: Alignment.center,
      child: Container(
        // Outer Device Mockup Container
        width: 320,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A24) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(44),
          border: Border.all(
            color: isDark ? const Color(0xFF1C2C3E) : Colors.black87,
            width: 12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Status bar area mimic with Speaker notch / camera cutout
            Container(
              height: 32,
              color: isDark ? const Color(0xFF0A0E14) : Colors.white,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Phone notch
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Mock Signal & Battery icons on right
                  Positioned(
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.signal_cellular_4_bar_rounded,
                          size: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.battery_std_rounded,
                          size: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  // Mock Time on left
                  Positioned(
                    left: 16,
                    child: Text(
                      '9:41',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inner Mock phone AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E14) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  // Mini Progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 0.45,
                        minHeight: 8,
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mock Heart / Streak counters
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Mock Content Viewport
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF0A0E14) : Colors.white,
                child: _blocks.isEmpty
                    ? _buildMockupEmptyState(isDark)
                    : ListView.builder(
                        controller: _previewScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 20,
                        ),
                        itemCount: _blocks.length,
                        itemBuilder: (context, index) {
                          final block = _blocks[index];
                          final isHighlighted = index == _hoveredOrFocusedIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _hoveredOrFocusedIndex = index;
                              });
                              _syncScroll(index, false);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF152232)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isHighlighted
                                      ? const Color(0xFF2ECC71)
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              )),
                                  width: isHighlighted ? 2.5 : 1,
                                ),
                                boxShadow: isHighlighted
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2ECC71,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.03,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: IgnorePointer(
                                child: DynamicBlockBuilder(
                                  lessonId: widget.lessonId,
                                  block: block,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Content Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create blocks on the left editor panel. They will instantly render here in real-time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white30 : Colors.black45,
                height: 1.4,
              ),
            ),
          ],
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
                  onTap: () => context.go(
                    _lesson != null && _lesson!.categoryId.isNotEmpty
                        ? '/admin/lessons?categoryId=${_lesson!.categoryId}'
                        : '/admin/lessons',
                  ),
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
            isWide
                ? Row(
                    children: [
                      ScaleButton(
                        onPressed: () => context.go(
                          _lesson != null && _lesson!.categoryId.isNotEmpty
                              ? '/admin/lessons?categoryId=${_lesson!.categoryId}'
                              : '/admin/lessons',
                        ),
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
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
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
                      const SizedBox(width: 10),
                      ScaleButton(
                        onPressed: () => AddBlockSheet.show(context, _addBlock),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add Block',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
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
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
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
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ScaleButton(
                            onPressed: () => context.go(
                              _lesson != null && _lesson!.categoryId.isNotEmpty
                                  ? '/admin/lessons?categoryId=${_lesson!.categoryId}'
                                  : '/admin/lessons',
                            ),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_hasChanges) ...[
                            ScaleButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
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
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Save',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          ScaleButton(
                            onPressed: () =>
                                AddBlockSheet.show(context, _addBlock),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Block',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!_hasChanges)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.1),
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
