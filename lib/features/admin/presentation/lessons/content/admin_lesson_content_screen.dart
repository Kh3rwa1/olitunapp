import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/csv_helper.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../../shared/models/content_item_extensions.dart';
import '../../../../../shared/providers/content_providers.dart';
import '../../../../categories/domain/entities/category_entity.dart';
import '../../../../categories/presentation/providers/category_notifier.dart';
import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../lessons/presentation/providers/lesson_notifier.dart';
import 'controllers/block_reorder_controller.dart';
import 'widgets/lesson_content_top_bar.dart';
import 'widgets/lesson_editor_block_list.dart';
import 'widgets/lesson_mockup_preview.dart';
import 'widgets/lesson_summary_banner.dart';
import 'widgets/universal_block_sheet.dart';

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
  bool _changedDuringSave = false;
  ContentItem? _contentItem;
  LessonEntity? _lesson;

  void _markDirty() {
    if (_isSaving) {
      _changedDuringSave = true;
    } else {
      _hasChanges = true;
    }
  }

  late ScrollController _leftScrollController;
  late ScrollController _previewScrollController;
  int? _hoveredOrFocusedIndex;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _leftScrollController = ScrollController();
    _previewScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _leftScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _syncScroll(int index, bool fromLeftToRight) {
    if (fromLeftToRight) {
      if (_previewScrollController.hasClients) {
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

  Future<void> _loadData() async {
    try {
      final repo = ref.read(contentRepositoryProvider);
      final result = await repo.get(ContentKind.lesson, widget.lessonId);
      result.fold(
        (failure) {
          if (mounted) context.go('/admin/lessons');
        },
        (item) {
          _contentItem = item;
          _lesson = item.toLessonEntity();
          _blocks = List.from(_lesson!.blocks);
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (mounted) context.go('/admin/lessons');
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _hasChanges && !_isSaving) {
        _saveChanges();
      }
    });
  }

  String get _backRoute => _lesson != null && _lesson!.categoryId.isNotEmpty
      ? '/admin/lessons?categoryId=${_lesson!.categoryId}'
      : '/admin/lessons';

  Future<void> _navigateBack() async {
    if (_hasChanges) {
      _autoSaveTimer?.cancel();
      await _saveChanges();
    }
    if (mounted) context.go(_backRoute);
  }

  Future<void> _saveChanges() async {
    if (_contentItem == null || _isSaving) return;

    setState(() => _isSaving = true);
    _changedDuringSave = false;

    try {
      final contentBlocks = _blocks
          .asMap()
          .entries
          .map((e) => e.value.toContentBlock(e.key))
          .toList();

      final updatedItem = _contentItem!.copyWith(
        blocks: contentBlocks,
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(contentRepositoryProvider);
      final result = await repo.upsert(updatedItem);

      result.fold(
        (failure) {
          setState(() => _isSaving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save: ${failure.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (savedItem) {
          _contentItem = savedItem;
          _lesson = savedItem.toLessonEntity();
          _blocks = List.from(_lesson!.blocks);

          ref.invalidate(contentListProvider((ContentKind.lesson, null)));
          if (_lesson != null && _lesson!.categoryId.isNotEmpty) {
            ref.invalidate(
              contentListProvider((ContentKind.lesson, _lesson!.categoryId)),
            );
          }
          ref.invalidate(
            contentDetailProvider((ContentKind.lesson, widget.lessonId)),
          );
          // ignore: deprecated_member_use
          ref.invalidate(lessonNotifierProvider);

          setState(() {
            _isSaving = false;
            if (_changedDuringSave) {
              _hasChanges = true;
              _changedDuringSave = false;
              _scheduleAutoSave();
            } else {
              _hasChanges = false;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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
        },
      );
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

  void _openBlockSheet({int? index, LessonBlockEntity? existing}) {
    if (index != null) setState(() => _hoveredOrFocusedIndex = index);
    final slug = (_contentItem?.title ?? '').toLowerCase().trim();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UniversalBlockSheet(
        existing: existing,
        categorySlug: slug,
        onSubmit: (block) {
          if (existing == null) {
            setState(() {
              _blocks.add(block);
              _markDirty();
              _hoveredOrFocusedIndex = _blocks.length - 1;
            });
          } else {
            _updateBlock(index ?? _blocks.indexOf(existing), block);
          }
          _scheduleAutoSave();
        },
      ),
    );
  }

  void _updateBlock(int index, LessonBlockEntity block) {
    setState(() {
      _blocks[index] = block;
      _markDirty();
    });
    _scheduleAutoSave();
  }

  void _removeBlock(int index) {
    final block = _blocks[index];
    setState(() {
      _blocks.removeAt(index);
      _markDirty();
    });
    _scheduleAutoSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${block.type} block'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _blocks.insert(index, block);
              _markDirty();
            });
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _exportBlocksToCsv() async {
    const csvHeader =
        'Index,Block Type,Block ID,Markdown/Text,Ol Chiki,Latin,Media URL,Caption/Transcript,Meta JSON\n';

    final csvRows = _blocks
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final entity = entry.value;
          final block = entity.toContentBlock(index);

          String markdownText = '';
          String olChiki = '';
          String latin = '';
          String mediaUrl = '';
          String captionTranscript = '';

          if (block is TextBlock) {
            markdownText = block.markdown;
            olChiki = block.textOlChiki ?? '';
            latin = block.textLatin ?? '';
          } else if (block is ImageBlock) {
            mediaUrl = block.media.url;
            captionTranscript = block.caption ?? '';
          } else if (block is VideoBlock) {
            mediaUrl = block.media.url;
          } else if (block is AudioBlock) {
            mediaUrl = block.media.url;
            captionTranscript = block.transcript ?? '';
          } else if (block is LottieBlock) {
            mediaUrl = block.media.url;
          } else if (block is QuizBlock) {
            markdownText = 'Quiz ID: ${block.quizId}';
          } else if (block is GlyphBlock) {
            olChiki = block.olChiki;
            latin = block.latin;
            mediaUrl = block.audioUrl ?? '';
          } else if (block is CalloutBlock) {
            markdownText = block.text;
            latin = block.variant.name;
          } else if (block is TracingBlock) {
            olChiki = block.config.glyph;
          }

          final metaStr = block.meta.isNotEmpty ? jsonEncode(block.meta) : '';

          return <String>[
                (index + 1).toString(),
                block.type,
                block.id,
                markdownText,
                olChiki,
                latin,
                mediaUrl,
                captionTranscript,
                metaStr,
              ]
              .map((val) {
                final escaped = val.replaceAll('"', '""');
                return '"$escaped"';
              })
              .join(',');
        })
        .join('\n');

    final csvFilename =
        'Olitun_Lesson_${_lesson?.titleLatin ?? widget.lessonId}_Blocks_Export.csv';

    try {
      await saveAndShareCsv(
        csvContent: csvHeader + csvRows,
        filename: csvFilename,
        shareSubject: 'Olitun Lesson ${_lesson?.titleLatin} Blocks Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      _blocks = reorderLessonBlocks(_blocks, oldIndex, newIndex);
      _markDirty();
    });
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 1024;

    final categories = ref.watch(categoryNotifierProvider).value ?? [];
    CategoryEntity? category;
    if (_contentItem != null && _contentItem!.categoryId.isNotEmpty) {
      for (final cat in categories) {
        if (cat.id == _contentItem!.categoryId) {
          category = cat;
          break;
        }
      }
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _navigateBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            LessonContentTopBar(
              lesson: _lesson,
              isDark: isDark,
              isWide: isWide,
              hasChanges: _hasChanges,
              isSaving: _isSaving,
              onNavigateBack: _navigateBack,
              onSaveChanges: _saveChanges,
              onOpenAddBlockSheet: _openBlockSheet,
              onExportCsv: _exportBlocksToCsv,
            ),
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              LessonSummaryBanner(
                                blocks: _blocks,
                                isDark: isDark,
                                isWide: isWide,
                              ),
                              Expanded(
                                child: _blocks.isEmpty
                                    ? LessonEmptyBlocksState(
                                        isDark: isDark,
                                        onAddFirstBlock: _openBlockSheet,
                                      )
                                    : LessonEditorBlockList(
                                        scrollController: _leftScrollController,
                                        blocks: _blocks,
                                        hoveredOrFocusedIndex:
                                            _hoveredOrFocusedIndex,
                                        isDark: isDark,
                                        isWide: isWide,
                                        categoryId: _contentItem?.categoryId,
                                        categorySlug: category?.titleLatin,
                                        onReorder: _moveBlock,
                                        onEditBlock: (idx, block) =>
                                            _openBlockSheet(
                                              index: idx,
                                              existing: block,
                                            ),
                                        onDeleteBlock: _removeBlock,
                                        onSelectBlock: (idx) =>
                                            _syncScroll(idx, true),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        Expanded(
                          flex: 4,
                          child: LessonMockupPreview(
                            lessonId: widget.lessonId,
                            blocks: _blocks,
                            previewScrollController: _previewScrollController,
                            hoveredOrFocusedIndex: _hoveredOrFocusedIndex,
                            isDark: isDark,
                            onBlockTapped: (idx) {
                              setState(() {
                                _hoveredOrFocusedIndex = idx;
                              });
                              _syncScroll(idx, false);
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        LessonSummaryBanner(
                          blocks: _blocks,
                          isDark: isDark,
                          isWide: isWide,
                        ),
                        Expanded(
                          child: _blocks.isEmpty
                              ? LessonEmptyBlocksState(
                                  isDark: isDark,
                                  onAddFirstBlock: _openBlockSheet,
                                )
                              : LessonEditorBlockList(
                                  blocks: _blocks,
                                  hoveredOrFocusedIndex: _hoveredOrFocusedIndex,
                                  isDark: isDark,
                                  isWide: isWide,
                                  categoryId: _contentItem?.categoryId,
                                  categorySlug: category?.titleLatin,
                                  onReorder: _moveBlock,
                                  onEditBlock: (idx, block) => _openBlockSheet(
                                    index: idx,
                                    existing: block,
                                  ),
                                  onDeleteBlock: _removeBlock,
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openBlockSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.elevatedButtonFg,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Block',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
