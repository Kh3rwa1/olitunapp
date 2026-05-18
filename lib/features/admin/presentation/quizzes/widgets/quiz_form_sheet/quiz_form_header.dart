import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';

class QuizFormHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const QuizFormHeader({
    super.key,
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
                  isEditing ? 'Edit Quiz' : 'Create Quiz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
