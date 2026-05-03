import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../lessons/presentation/providers/lesson_notifier.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/gamified_card.dart';
import 'widgets/admin_upload_field.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_header.dart';
import 'widgets/admin_form_widgets.dart';

class AdminLessonsScreen extends ConsumerStatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  ConsumerState<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends ConsumerState<AdminLessonsScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),

                // Category Filter
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 20,
                  ),
                  child: categoriesAsync.when(
                    data: (categories) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Lessons',
                            isSelected: _selectedCategoryId == null,
                            onTap: () =>
                                setState(() => _selectedCategoryId = null),
                            isDark: isDark,
                          ),
                          ...categories.map(
                            (img) => Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _FilterChip(
                                label: img.titleLatin,
                                isSelected: _selectedCategoryId == img.id,
                                onTap: () => setState(
                                  () => _selectedCategoryId = img.id,
                                ),
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: lessonsAsync.when(
                    data: (lessons) {
                      final filteredLessons = _selectedCategoryId == null
                          ? lessons
                          : lessons
                                .where(
                                  (l) => l.categoryId == _selectedCategoryId,
                                )
                                .toList();

                      return filteredLessons.isEmpty
                          ? _buildEmptyState(context, isDark)
                          : _buildLessonsList(
                              filteredLessons,
                              isDark,
                              isWideScreen,
                            );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLessonDialog(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Lesson',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(color: AdminTokens.base(isDark));
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isWideScreen) ...[
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTokens.sunken(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                border: Border.all(color: AdminTokens.border(isDark)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AdminTokens.textPrimary(isDark),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AdminPageHeader(
            title: 'Lessons',
            subtitle: 'Create and manage learning content',
            eyebrow: 'CONTENT · LESSONS',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AdminEmptyState(
      icon: Icons.school_outlined,
      title: 'No lessons found',
      message: 'Create your first lesson to get learners started.',
      actionLabel: 'Add Lesson',
      onAction: () => _showLessonDialog(context, null),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildLessonsList(
    List<LessonEntity> lessons,
    bool isDark,
    bool isWideScreen,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _LessonCard(
          lesson: lesson,
          isDark: isDark,
          onEdit: () => _showLessonDialog(context, lesson),
          onDelete: () => _showDeleteDialog(context, lesson),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  void _showLessonDialog(BuildContext context, LessonEntity? lesson) {
    final isEditing = lesson != null;
    final categories =
        ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];
    var selectedCategoryId =
        lesson?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    final titleLatinController = TextEditingController(
      text: lesson?.titleLatin ?? '',
    );
    final titleOlChikiController = TextEditingController(
      text: lesson?.titleOlChiki ?? '',
    );
    final descriptionController = TextEditingController(
      text: lesson?.description ?? '',
    );
    final minutesController = TextEditingController(
      text: (lesson?.estimatedMinutes ?? 5).toString(),
    );
    final orderController = TextEditingController(
      text: (lesson?.order ?? 0).toString(),
    );
    final thumbnailController = TextEditingController(
      text: lesson?.data?['thumbnailUrl'] ?? '',
    );
    var level = 'beginner';
    var isActive = lesson?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => Container(
            height: MediaQuery.of(context).size.height * 0.86,
            decoration: BoxDecoration(
              color: AdminTokens.overlay(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AdminTokens.radius2xl),
              ),
              boxShadow: AdminTokens.overlayShadow(isDark),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTokens.borderStrong(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Lesson' : 'Create Lesson',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      _buildTextField(
                        controller: titleLatinController,
                        label: 'Title (Latin)',
                        hint: 'Enter lesson title',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: titleOlChikiController,
                        label: 'Title (Ol Chiki)',
                        hint: 'ᱯᱟᱲᱦᱟ ᱫᱟᱨᱮ',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Short lesson description',
                        isDark: isDark,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.titleLatin),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedCategoryId = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: minutesController,
                              label: 'Minutes',
                              hint: '5',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: orderController,
                              label: 'Order',
                              hint: '0',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Level',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: level,
                        items: const [
                          DropdownMenuItem(
                            value: 'beginner',
                            child: Text('Beginner'),
                          ),
                          DropdownMenuItem(
                            value: 'intermediate',
                            child: Text('Intermediate'),
                          ),
                          DropdownMenuItem(
                            value: 'advanced',
                            child: Text('Advanced'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => level = value);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AdminUploadField(
                        controller: thumbnailController,
                        label: 'Thumbnail',
                        icon: Icons.image_rounded,
                        isDark: isDark,
                        folder: 'lesson-thumbnails',
                        uploadType: AdminUploadType.image,
                        dialogSetState: setDialogState,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) =>
                            setDialogState(() => isActive = value),
                        title: const Text('Active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedCategoryId == null
                              ? null
                              : () async {
                                  final newLesson = LessonEntity(
                                    id: lesson?.id ?? const Uuid().v4(),
                                    categoryId: selectedCategoryId!,
                                    titleLatin: titleLatinController.text
                                        .trim(),
                                    titleOlChiki: titleOlChikiController.text
                                        .trim(),
                                    description:
                                        descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : descriptionController.text.trim(),
                                    estimatedMinutes:
                                        int.tryParse(
                                          minutesController.text.trim(),
                                        ) ??
                                        5,
                                    order:
                                        int.tryParse(
                                          orderController.text.trim(),
                                        ) ??
                                        0,
                                    blocks:
                                        lesson?.blocks ?? const <LessonBlockEntity>[],
                                  );

                                  if (isEditing) {
                                    await ref
                                        .read(lessonNotifierProvider.notifier)
                                        .updateLesson(newLesson);
                                  } else {
                                    await ref
                                        .read(lessonNotifierProvider.notifier)
                                        .addLesson(newLesson);
                                  }

                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Lesson',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    LessonEntity lesson,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Lesson',
      message:
          'This will permanently delete "${lesson.titleLatin}". This action cannot be undone.',
    );
    if (ok == true) {
      await ref.read(lessonNotifierProvider.notifier).deleteLesson(lesson.id);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return AdminTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.lesson,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GamifiedCard(
        color: AdminTokens.raised(isDark),
        borderRadius: AdminTokens.radiusXl,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AdminTokens.accentSoft(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                border: Border.all(color: AdminTokens.accentBorder(isDark)),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AdminTokens.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.titleOlChiki,
                    style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.blocks.length} content blocks',
                    style: AdminTokens.label(isDark),
                  ),
                ],
              ),
            ),
            AdminIconAction(
              icon: Icons.edit_note_rounded,
              tooltip: 'Edit Details',
              onTap: onEdit,
            ),
            const SizedBox(width: 6),
            AdminIconAction(
              icon: Icons.playlist_add_rounded,
              tooltip: 'Edit Content',
              onTap: () => context.go('/admin/lessons/content/${lesson.id}'),
            ),
            const SizedBox(width: 6),
            AdminIconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              destructive: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
