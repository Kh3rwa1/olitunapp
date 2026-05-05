import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ═══════════════ QUIZ PERFORMANCE CARD ═══════════════

class QuizPerformanceCard extends StatelessWidget {
  final int quizzes;
  final int accuracy;
  final int bestScore;
  final bool isDark;

  const QuizPerformanceCard({
    super.key,
    required this.quizzes,
    required this.accuracy,
    required this.bestScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.duoBlue, AppColors.duoBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.duoBlue.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left — accuracy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Score',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$accuracy%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 4),
                          child: Text(
                            'Avg',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right — stats pills
              Column(
                children: [
                  _QuizMiniStat(value: '$quizzes', label: 'Total'),
                  const SizedBox(height: 8),
                  _QuizMiniStat(value: '$bestScore%', label: 'Best'),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _QuizMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _QuizMiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
