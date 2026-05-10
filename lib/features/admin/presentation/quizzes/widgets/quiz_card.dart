import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/models/content_models.dart';
import '../../widgets/admin_form_widgets.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
          border: Border.all(color: AdminTokens.border(isDark)),
          boxShadow: AdminTokens.raisedShadow(isDark),
        ),
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
                Icons.quiz_rounded,
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
                    quiz.title ?? 'Untitled Quiz',
                    style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quiz.questions.length} questions',
                    style: AdminTokens.label(isDark),
                  ),
                ],
              ),
            ),
            AdminIconAction(
              icon: Icons.edit_rounded,
              tooltip: 'Edit',
              onTap: onEdit,
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
