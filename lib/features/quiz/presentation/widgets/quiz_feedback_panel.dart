import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String correctOptionOlChiki;
  final String correctOptionLatin;
  final VoidCallback onContinue;

  const QuizFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.correctOptionOlChiki,
    required this.correctOptionLatin,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isCorrect
        ? (isDark ? const Color(0xFF0F2E1E) : const Color(0xFFE8FDF0))
        : (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFDE8E8));

    final borderColor = isCorrect
        ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFB9F6CA))
        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFCDD2));

    final textColor = isCorrect
        ? (isDark ? const Color(0xFF5DFFA8) : const Color(0xFF1B5E20))
        : (isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C));

    final iconColor = isCorrect
        ? (isDark ? const Color(0xFF1EE088) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF5252) : const Color(0xFFC62828));

    final titleText = isCorrect
        ? (isDark ? 'Sange! (Correct)' : 'Correct!')
        : 'Incorrect';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: borderColor, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Text(
              'Correct Answer:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (correctOptionOlChiki.isNotEmpty) ...[
                  Text(
                    correctOptionOlChiki,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OlChiki',
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    correctOptionLatin,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect
                    ? AppColors.primary
                    : AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, duration: 250.ms, curve: Curves.easeOutQuad);
  }
}
