import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/shared/models/content/quiz_model.dart';

class QuizBlockCTAWidget extends StatelessWidget {
  final String quizId;
  final QuizModel quiz;
  final Color accentColor;
  final bool isDark;
  final double maxHeight;
  final int index;
  final VoidCallback onDismiss;
  final Widget Function({
    required Color themeColor,
    required bool isDark,
    required double radius,
    required double padding,
    required Widget child,
  }) buildGlassCard;
  final Widget Function({
    required Color color,
    required VoidCallback onPressed,
    required Widget child,
  }) buildTactileButton;

  const QuizBlockCTAWidget({
    super.key,
    required this.quizId,
    required this.quiz,
    required this.accentColor,
    required this.isDark,
    required this.maxHeight,
    required this.index,
    required this.onDismiss,
    required this.buildGlassCard,
    required this.buildTactileButton,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: buildGlassCard(
              themeColor: accentColor,
              isDark: isDark,
              radius: 28,
              padding: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: accentColor,
                      size: 38,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to test yourself?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great job! Take "${quiz.title ?? 'the quiz'}" now to test your knowledge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  buildTactileButton(
                    color: accentColor,
                    onPressed: () {
                      context.push('/quiz/$quizId');
                    },
                    child: Text(
                      'TAKE THE QUIZ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color:
                            ThemeData.estimateBrightnessForColor(accentColor) ==
                                    Brightness.light
                                ? Colors.black
                                : Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
