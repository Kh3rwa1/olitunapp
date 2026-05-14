import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../categories/domain/entities/category_entity.dart';

import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_upload_field.dart';

class LessonFormSheet extends ConsumerStatefulWidget {
  final LessonEntity? lesson;

  const LessonFormSheet({super.key, this.lesson});

  static void show(BuildContext context, WidgetRef ref, LessonEntity? lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LessonFormSheet(lesson: lesson),
    );
  }

  @override
  ConsumerState<LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends ConsumerState<LessonFormSheet> {
  late final TextEditingController _titleLatinCtrl;
  late final TextEditingController _titleOlChikiCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _thumbnailCtrl;

  String? _selectedCategoryId;
  String _level = 'beginner';
  bool _isActive = true;

  bool get _isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    final categories =
        ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];

    _selectedCategoryId =
        lesson?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    _titleLatinCtrl = TextEditingController(text: lesson?.titleLatin ?? '');
    _titleOlChikiCtrl = TextEditingController(text: lesson?.titleOlChiki ?? '');
    _descriptionCtrl = TextEditingController(text: lesson?.description ?? '');
    _minutesCtrl = TextEditingController(
      text: (lesson?.estimatedMinutes ?? 5).toString(),
    );
    _orderCtrl = TextEditingController(text: (lesson?.order ?? 0).toString());
    _thumbnailCtrl = TextEditingController(
      text: lesson?.data?['thumbnailUrl'] ?? '',
    );

    _isActive = lesson?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleLatinCtrl.dispose();
    _titleOlChikiCtrl.dispose();
    _descriptionCtrl.dispose();
    _minutesCtrl.dispose();
    _orderCtrl.dispose();
    _thumbnailCtrl.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories =
        ref.read(categoryNotifierProvider).value ?? const <CategoryEntity>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Lesson' : 'Create Lesson',
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
                  controller: _titleLatinCtrl,
                  label: 'Title (Latin)',
                  hint: 'Enter lesson title',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleOlChikiCtrl,
                  label: 'Title (Ol Chiki)',
                  hint: 'ᱯᱟᱲᱦᱟ ᱫᱟᱨᱮ',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionCtrl,
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
                  initialValue: _selectedCategoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.titleLatin),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
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
                        controller: _minutesCtrl,
                        label: 'Minutes',
                        hint: '5',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _orderCtrl,
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
                  initialValue: _level,
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
                      setState(() => _level = value);
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
                  controller: _thumbnailCtrl,
                  label: 'Thumbnail',
                  icon: Icons.image_rounded,
                  isDark: isDark,
                  folder: 'lesson-thumbnails',
                  dialogSetState: setState,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
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
                    onPressed: _selectedCategoryId == null
                        ? null
                        : () async {
                            final newLesson = LessonEntity(
                              id: widget.lesson?.id ?? const Uuid().v4(),
                              categoryId: _selectedCategoryId!,
                              titleLatin: _titleLatinCtrl.text.trim(),
                              titleOlChiki: _titleOlChikiCtrl.text.trim(),
                              description: _descriptionCtrl.text.trim().isEmpty
                                  ? null
                                  : _descriptionCtrl.text.trim(),
                              estimatedMinutes:
                                  int.tryParse(_minutesCtrl.text.trim()) ?? 5,
                              order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
                              blocks:
                                  widget.lesson?.blocks ??
                                  const [
                                    LessonBlockEntity(
                                      type: 'text',
                                      textLatin: 'New Block',
                                      textOlChiki: 'New Block',
                                    ),
                                  ],
                              isActive: _isActive,
                              data: _thumbnailCtrl.text.isNotEmpty
                                  ? {'thumbnailUrl': _thumbnailCtrl.text}
                                  : null,
                            );

                            if (_isEditing) {
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
                    child: Text(_isEditing ? 'Save Changes' : 'Create Lesson'),
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
