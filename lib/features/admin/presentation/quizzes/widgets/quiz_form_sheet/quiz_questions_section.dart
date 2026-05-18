import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/content_models.dart';

class QuizQuestionsSection extends StatelessWidget {
  final List<QuizQuestion> questions;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onEditQuestion;
  final ValueChanged<int> onDeleteQuestion;

  const QuizQuestionsSection({
    super.key,
    required this.questions,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Questions (${questions.length})',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAddQuestion,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 40,
                  color: AdminTokens.textTertiary(isDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'No questions yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminTokens.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Add" to create MCQ or Fill-in-the-blank questions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTokens.textTertiary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ...List.generate(questions.length, (i) {
          final q = questions[i];
          final isFillBlank = q.type == 'fill_blank';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTokens.raised(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isFillBlank
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isFillBlank
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isFillBlank
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isFillBlank ? 'FILL BLANK' : 'MCQ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isFillBlank
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.promptOlChiki.isNotEmpty
                            ? q.promptOlChiki
                            : (q.blankSentenceOlChiki ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AdminTokens.bodyStrong(
                          isDark,
                        ).copyWith(fontSize: 13),
                      ),
                      if (q.promptLatin != null || q.blankSentenceLatin != null)
                        Text(
                          q.promptLatin ?? q.blankSentenceLatin ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTokens.textTertiary(isDark),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  onPressed: () => onEditQuestion(i),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  onPressed: () => onDeleteQuestion(i),
                  tooltip: 'Delete',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
