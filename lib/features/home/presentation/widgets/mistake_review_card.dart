import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../../core/motion/motion.dart';
import '../../../quiz/presentation/providers/mistake_provider.dart';

class MistakeReviewCard extends ConsumerWidget {
  const MistakeReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(mistakeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (mistakes.isEmpty) return const SizedBox.shrink();

    final count = mistakes.length;

    return AnimatedBentoChild(
      index: 2,
      child: PressableScale(
        onTap: () => context.push('/mistakes'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF2C1B1B).withValues(alpha: 0.8),
                      const Color(0xFF1F1212).withValues(alpha: 0.6),
                    ]
                  : [const Color(0xFFFFF5F5), const Color(0xFFFFF0F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4A2525).withValues(alpha: 0.5)
                  : const Color(0xFFFCA5A5).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.red.shade100).withValues(
                  alpha: isDark ? 0.3 : 0.4,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF4A2525).withValues(alpha: 0.3)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.healing_rounded,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MISTAKE REVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : Colors.red.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF4A2525).withValues(alpha: 0.5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Takes 2 min',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFFCA5A5)
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$count word${count > 1 ? 's' : ''} need${count > 1 ? '' : 's'} practice',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '“Mistakes are just lessons asking for a second chance.”',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Practice Now',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : Colors.red.shade700,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
