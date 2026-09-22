import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../../shared/providers/providers.dart';

// ═══════════════ HERO QUIZ CARD ═══════════════

class HeroQuizCard extends ConsumerWidget {
  final QuizModel quiz;
  final bool isDark;

  const HeroQuizCard({super.key, required this.quiz, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    return BentoCell(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentOchre, AppColors.accentOchreDark],
      ),
      borderRadius: 32,
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentOchre.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
      ],
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child:
                Icon(
                      Icons.quiz_rounded,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.15),
                    )
                    .animate(
                      onPlay: reduceVisualEffects
                          ? null
                          : (c) => c.repeat(reverse: true),
                    )
                    .moveY(begin: 0, end: -8, duration: 1800.ms)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1800.ms,
                    ),
          ),
          Positioned(
            right: 60,
            top: 8,
            child:
                Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    )
                    .animate(
                      onPlay: reduceVisualEffects
                          ? null
                          : (c) => c.repeat(reverse: true),
                    )
                    .fadeIn(duration: 600.ms)
                    .then()
                    .fadeOut(duration: 600.ms),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLevelEmoji(quiz.level),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                quiz.title ?? 'Quiz Challenge',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${quiz.questions.length} questions • ${quiz.level}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.accentOchreDark,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'START QUIZ',
                          style: TextStyle(
                            color: AppColors.accentOchreDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(
                    onPlay: reduceVisualEffects
                        ? null
                        : (c) => c.repeat(reverse: true),
                  )
                  .shimmer(
                    delay: 2.seconds,
                    duration: 1500.ms,
                    color: AppColors.accentOchre.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════ BENTO QUIZ CARD ═══════════════

class BentoQuizCard extends StatelessWidget {
  final QuizModel quiz;
  final int index;
  final bool isDark;

  const BentoQuizCard({
    super.key,
    required this.quiz,
    required this.index,
    required this.isDark,
  });

  static const List<Color> _badgeColors = [
    AppColors.quizBadgeA,
    AppColors.quizBadgeB,
    AppColors.quizBadgeC,
    AppColors.quizBadgeD,
  ];

  static const List<IconData> _icons = [
    Icons.abc_rounded,
    Icons.numbers_rounded,
    Icons.spellcheck_rounded,
    Icons.quiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColors[index % 4];
    final icon = _icons[index % 4];

    return BentoCell(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),

          // Title
          Flexible(
            child: Text(
              quiz.title ?? 'Quiz ${index + 2}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Meta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : badgeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${quiz.questions.length} questions',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : badgeColor,
              ),
            ),
          ),

          const Spacer(),

          // Level + Arrow
          Row(
            children: [
              Text(
                _getLevelEmoji(quiz.level),
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _getLevelEmoji(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return '⭐';
    case 'intermediate':
      return '⭐⭐';
    case 'advanced':
      return '⭐⭐⭐';
    default:
      return '⭐';
  }
}
