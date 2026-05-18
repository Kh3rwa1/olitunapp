import 'package:flutter/material.dart';
import '../../../../../categories/domain/entities/category_entity.dart';
import '../../../widgets/admin_form_widgets.dart';

class QuizBasicInfoSection extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController orderCtrl;
  final TextEditingController passingScoreCtrl;
  final String? selectedCategoryId;
  final String level;
  final bool isActive;
  final List<CategoryEntity> categories;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<bool> onActiveChanged;

  const QuizBasicInfoSection({
    super.key,
    required this.titleCtrl,
    required this.orderCtrl,
    required this.passingScoreCtrl,
    required this.selectedCategoryId,
    required this.level,
    required this.isActive,
    required this.categories,
    required this.onCategoryChanged,
    required this.onLevelChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminTextField(
          controller: titleCtrl,
          label: 'Title',
          hint: 'Enter quiz title',
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
          initialValue: selectedCategoryId,
          items: categories
              .map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.titleLatin)),
              )
              .toList(),
          onChanged: onCategoryChanged,
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
              child: AdminTextField(
                controller: orderCtrl,
                label: 'Order',
                hint: '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminTextField(
                controller: passingScoreCtrl,
                label: 'Passing Score',
                hint: '70',
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
          initialValue: level,
          items: const [
            DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
            DropdownMenuItem(
              value: 'intermediate',
              child: Text('Intermediate'),
            ),
            DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
          ],
          onChanged: (v) {
            if (v != null) onLevelChanged(v);
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
        const SizedBox(height: 12),
        SwitchListTile(
          value: isActive,
          onChanged: onActiveChanged,
          title: const Text('Active'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
