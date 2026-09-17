import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/presentation/layout/responsive_layout.dart';
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

  void _handleContinue() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics unsupported on simulators — safe to ignore.
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final backgroundColor = widget.isCorrect
        ? (isDark
              ? AppColors.quizFeedbackSuccessDarkBg
              : AppColors.quizFeedbackSuccessLightBg)
        : (isDark
              ? AppColors.quizFeedbackErrorDarkBg
              : AppColors.quizFeedbackErrorLightBg);

    final borderColor = widget.isCorrect
        ? (isDark
              ? AppColors.quizFeedbackSuccessDarkBorder
              : AppColors.quizFeedbackSuccessLightBorder)
        : (isDark
              ? AppColors.quizFeedbackErrorDarkBorder
              : AppColors.quizFeedbackErrorLightBorder);

    final textColor = widget.isCorrect
        ? (isDark
              ? AppColors.quizFeedbackSuccessDarkFg
              : AppColors.quizFeedbackSuccessLightFg)
        : (isDark
              ? AppColors.quizFeedbackErrorDarkFg
              : AppColors.quizFeedbackErrorLightFg);

    final iconColor = widget.isCorrect
        ? (isDark
              ? AppColors.quizFeedbackSuccessDarkIcon
              : AppColors.quizFeedbackSuccessLightIcon)
        : (isDark
              ? AppColors.quizFeedbackErrorDarkIcon
              : AppColors.quizFeedbackErrorLightIcon);

    final titleText = widget.isCorrect
        ? (isDark ? 'Sange! (Correct)' : 'Correct!')
        : 'Incorrect';

    final String olChiki = widget.correctOptionOlChiki.trim();
    final String latin = widget.correctOptionLatin.trim();
    final bool hasDistinctOlChiki = olChiki.isNotEmpty && olChiki != latin;

    // Premium dynamic fallback explanations for absolute premium experience
    final String displayExplanation;
    if (widget.explanation != null && widget.explanation!.trim().isNotEmpty) {
      displayExplanation = widget.explanation!.trim();
    } else if (widget.isCorrect) {
      if (hasDistinctOlChiki) {
        displayExplanation =
            'Splendid! You matched "$olChiki" with its designated sound "$latin". Your recall is spot-on!';
      } else {
        displayExplanation =
            'Excellent! You correctly identified the right match. Keep up the great work!';
      }
    } else {
      if (hasDistinctOlChiki) {
        displayExplanation =
            'The designated match is "$olChiki" ($latin). Review its shape and sound carefully!';
      } else if (latin.isNotEmpty) {
        displayExplanation =
            'The designated match is "$latin". Review its shape and sound carefully!';
      } else {
        displayExplanation =
            'Don\'t worry! Review the options and try to recall the corresponding glyph.';
      }
    }

    final maxHeight = MediaQuery.of(context).size.height * 0.55;

    final panel = Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
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
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveLayout.maxNarrowWidth(context),
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
                    const SizedBox(height: 10),
                    Text(
                      'Correct Answer:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasDistinctOlChiki)
                      Row(
                        children: [
                          Text(
                            olChiki,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
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
                          Text(
                            latin,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        latin.isNotEmpty ? latin : olChiki,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isCorrect
                            ? AppColors.primary
                            : AppColors.error,
                        foregroundColor: widget.isCorrect
                            ? AppColors.elevatedButtonFg
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isDesktopWeb) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (widget.isCorrect
                                            ? Colors.black
                                            : Colors.white)
                                        .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Enter ↵',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isCorrect
                                      ? AppColors.elevatedButtonFg
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1.0, duration: 250.ms, curve: Curves.easeOutQuad);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _handleContinue,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _handleContinue,
        const SingleActivator(LogicalKeyboardKey.space): _handleContinue,
      },
      child: Focus(autofocus: true, child: panel),
    );
  }
}
