import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/motion/motion.dart';

class QuizCompleteScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const QuizCompleteScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = (score / totalQuestions * 100).round();
    final isPassing = percentage >= 70;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: isPassing
                              ? AppColors.premiumGreen
                              : AppColors.premiumOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isPassing
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withValues(alpha: 0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPassing
                              ? Icons.emoji_events_rounded
                              : Icons.refresh_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 36),
                  Text(
                    isPassing
                        ? AppLocalizations.of(context)!.wellDone
                        : AppLocalizations.of(context)!.keepPracticing,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.youScored(score, totalQuestions),
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: isPassing ? AppColors.success : AppColors.warning,
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.plusStars(score * 5),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                  const Spacer(),
                  GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.continueButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 400.ms)
                      .slideY(begin: 0.3),
                ],
              ),
            ),
          ),
          if (isPassing) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
