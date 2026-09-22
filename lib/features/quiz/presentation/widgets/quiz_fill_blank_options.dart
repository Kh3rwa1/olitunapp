import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../providers/quiz_session_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';

class QuizFillBlankOptions extends StatelessWidget {
  const QuizFillBlankOptions({
    super.key,
    required this.question,
    required this.state,
    required this.isDark,
    this.focusedIndex = -1,
    required this.onSelect,
  });

  final QuizQuestion question;
  final QuizSessionState state;
  final bool isDark;
  final int focusedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.selectMissingWord,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 16,
          children: List.generate(question.optionsOlChiki.length, (index) {
            final isCorrect = index == question.correctIndex;
            final isCurrentSelection = state.selectedAnswer == index;

            Color chipColor;
            Color textColor;
            BorderSide borderSide;

            if (state.isAnswered) {
              if (isCorrect) {
                chipColor = AppColors.success;
                textColor = Colors.white;
                borderSide = BorderSide.none;
              } else if (isCurrentSelection) {
                chipColor = AppColors.error;
                textColor = Colors.white;
                borderSide = BorderSide.none;
              } else {
                chipColor = isDark
                    ? AppColors.quizDarkBubble
                    : AppColors.quizLightBubble;
                textColor = isDark ? Colors.white30 : Colors.black26;
                borderSide = BorderSide.none;
              }
            } else {
              if (isCurrentSelection) {
                chipColor = isDark
                    ? AppColors.quizDarkCardAlt
                    : Colors.grey.shade100;
                textColor = Colors.transparent;
                borderSide = BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1.5,
                );
              } else {
                final isFocused = focusedIndex == index;
                chipColor = isDark
                    ? (isFocused
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.quizDarkCard)
                    : (isFocused
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.white);
                textColor = isDark ? Colors.white : Colors.black87;
                borderSide = BorderSide(
                  color: isFocused
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  width: isFocused ? 2.0 : 1.5,
                );
              }
            }

            final isDesktopWeb =
                kIsWeb ||
                defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux;

            return Semantics(
                  button: true,
                  enabled: !state.isAnswered && !isCurrentSelection,
                  selected: isCurrentSelection,
                  label:
                      'Missing word option ${index + 1}: ${question.optionsOlChiki[index]}',
                  value: state.isAnswered
                      ? (isCorrect
                            ? 'Correct answer'
                            : (isCurrentSelection ? 'Incorrect answer' : ''))
                      : null,
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      onTap: (state.isAnswered || isCurrentSelection)
                          ? null
                          : () => onSelect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.fromBorderSide(borderSide),
                          boxShadow: (!state.isAnswered && !isCurrentSelection)
                              ? [
                                  BoxShadow(
                                    color: (focusedIndex == index)
                                        ? AppColors.primary.withValues(
                                            alpha: 0.25,
                                          )
                                        : Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.08,
                                          ),
                                    blurRadius: (focusedIndex == index) ? 8 : 4,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              question.optionsOlChiki[index],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'OlChiki',
                                color: textColor,
                              ),
                            ),
                            if (isDesktopWeb &&
                                !state.isAnswered &&
                                !isCurrentSelection) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: (focusedIndex == index)
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: (focusedIndex == index)
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black45),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate(
                  key: ValueKey(
                    'chip-$index-${state.selectedAnswer}-${state.isAnswered}',
                  ),
                )
                .scale(begin: const Offset(0.95, 0.95), duration: 150.ms);
          }),
        ),
      ],
    );
  }
}
