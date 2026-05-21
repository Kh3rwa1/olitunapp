import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class QuizFeedbackPanel extends StatefulWidget {
  final bool isCorrect;
  final String correctOptionOlChiki;
  final String correctOptionLatin;
  final String? explanation;
  final VoidCallback onContinue;

  const QuizFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.correctOptionOlChiki,
    required this.correctOptionLatin,
    this.explanation,
    required this.onContinue,
  });

  @override
  State<QuizFeedbackPanel> createState() => _QuizFeedbackPanelState();
}

class _QuizFeedbackPanelState extends State<QuizFeedbackPanel> {
  @override
  void initState() {
    super.initState();
    _triggerHapticFeedback();
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      if (widget.isCorrect) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Safely ignore haptic errors on simulators
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = widget.isCorrect
        ? (isDark ? const Color(0xFF0F2E1E) : const Color(0xFFE8FDF0))
        : (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFDE8E8));

    final borderColor = widget.isCorrect
        ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFB9F6CA))
        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFCDD2));

    final textColor = widget.isCorrect
        ? (isDark ? const Color(0xFF5DFFA8) : const Color(0xFF1B5E20))
        : (isDark ? const Color(0xFFFF5252) : const Color(0xFFB71C1C));

    final iconColor = widget.isCorrect
        ? (isDark ? const Color(0xFF1EE088) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF5252) : const Color(0xFFC62828));

    final titleText = widget.isCorrect
        ? (isDark ? 'Sange! (Correct)' : 'Correct!')
        : 'Incorrect';

    // Premium dynamic fallback explanations for absolute premium experience
    final String displayExplanation =
        (widget.explanation != null && widget.explanation!.trim().isNotEmpty)
        ? widget.explanation!
        : (widget.isCorrect
              ? 'Splendid! You matched the correct Ol Chiki glyph "${widget.correctOptionOlChiki}" with its designated latin sound "${widget.correctOptionLatin}". Your learning retention is skyrocketing!'
              : 'Observe the shape of the character carefully. The glyph "${widget.correctOptionOlChiki}" corresponds directly to the sound "${widget.correctOptionLatin}". Study this relation to solidify your recall.');

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
                  color: widget.isCorrect
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
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
          if (!widget.isCorrect) ...[
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
                if (widget.correctOptionOlChiki.isNotEmpty) ...[
                  Text(
                    widget.correctOptionOlChiki,
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
                    widget.correctOptionLatin,
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

          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Insight & Guidance:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayExplanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                try {
                  HapticFeedback.lightImpact();
                } catch (_) {}
                widget.onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isCorrect
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
