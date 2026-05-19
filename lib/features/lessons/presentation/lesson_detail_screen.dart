import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/lesson_entity.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../shared/utils/localized_content.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

import 'widgets/dynamic_block_builder.dart';
import 'widgets/lesson_content_widgets.dart';
import '../../../core/motion/confetti_overlay.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonNotifierProvider);

    // Watch content providers to ensure data is available for dynamic block matching.
    ref.watch(lettersProvider);
    ref.watch(numbersProvider);
    ref.watch(wordsProvider);
    ref.watch(sentencesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lessons.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: _LessonStateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load this lesson',
          message: 'Check your connection and try again.',
          isDark: isDark,
          onBack: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return _LessonStateScaffold(
            isDark: isDark,
            child: _LessonStateMessage(
              icon: Icons.school_outlined,
              title: 'No lessons available',
              message: 'New learning content will appear here soon.',
              isDark: isDark,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
          );
        }

        final lesson = _findLesson(data, lessonId);
        if (lesson == null) {
          return _LessonStateScaffold(
            isDark: isDark,
            child: _LessonStateMessage(
              icon: Icons.search_off_rounded,
              title: 'Lesson not found',
              message: 'This lesson may have been moved or removed.',
              isDark: isDark,
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
          );
        }

        final completedLessons =
            ref.watch(userStatsProvider).value?.completedLessons ?? {};
        final scriptMode = ref.watch(effectiveScriptModeProvider);
        final lessonTitle = primaryLocalizedText(
          olChiki: lesson.titleOlChiki,
          latin: lesson.titleLatin,
          scriptMode: scriptMode,
        );
        if (!completedLessons.contains(lesson.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateLastOpenedLesson(ref, lesson.id);
          });
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ParallaxHeroSliverAppBar(
                gradient: AppColors.heroGradient,
                heroTag: MotionTokens.heroTag('lesson', lesson.id),
                glyph: lesson.titleOlChiki.isNotEmpty
                    ? lesson.titleOlChiki.characters.first
                    : null,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  lessonTitle,
                  style: TextStyle(
                    fontFamily: primaryLocalizedFontFamily(scriptMode),
                  ),
                ),
                heroChild: _LessonHeroSummary(
                  lesson: lesson,
                  scriptMode: scriptMode,
                  buildChip: _buildChip,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    // Description section
                    if (lesson.description != null &&
                        lesson.description!.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.aboutThisLesson,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content section based on category
                    FadeInSlide(
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSectionTitle(context, lesson.categoryId),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildContent(lesson, isDark),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: () {
                final notifier = ref.read(userStatsProvider.notifier);
                notifier.completeLesson(
                  lesson.id,
                  categoryId: lesson.categoryId,
                  estimatedMinutes: lesson.estimatedMinutes,
                );
                notifier.addStars(25);

                final quizzes = ref.read(quizzesProvider).value ?? [];
                final quizId = _getQuizIdForCategory(
                  lesson.categoryId,
                  quizzes,
                );

                _showCompletionSheet(
                  context: context,
                  lesson: lesson,
                  quizId: quizId,
                  quizzes: quizzes,
                );
              },
              backgroundColor: AppColors.primary,
              label: const Text(
                'Complete Lesson',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  LessonEntity? _findLesson(List<LessonEntity> lessons, String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) {
        return lesson;
      }
    }
    return null;
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionTitle(BuildContext context, String categoryId) {
    switch (categoryId) {
      case 'alphabets':
      case 'cat_alphabet':
      case 'seed_alphabet':
        return AppLocalizations.of(context)!.lettersToLearn;
      case 'numbers':
      case 'cat_numbers':
      case 'seed_numbers':
        return AppLocalizations.of(context)!.numbersToLearn;
      case 'words':
      case 'cat_words':
      case 'seed_words':
        return AppLocalizations.of(context)!.vocabulary;
      case 'sentences':
      case 'cat_sentences':
      case 'seed_sentences':
      case 'phrases':
        return AppLocalizations.of(context)!.commonPhrases;
      default:
        return AppLocalizations.of(context)!.content;
    }
  }

  Widget _buildContent(LessonEntity lesson, bool isDark) {
    // If valid blocks exist, render them dynamically
    if (lesson.blocks.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lesson.blocks.map((block) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DynamicBlockBuilder(lessonId: lesson.id, block: block),
          );
        }).toList(),
      );
    }

    // Fallback to provider-based grids
    switch (lesson.categoryId) {
      case 'alphabets':
      case 'cat_alphabet':
      case 'seed_alphabet':
        return LetterGridContent(lessonId: lesson.id);
      case 'numbers':
      case 'cat_numbers':
      case 'seed_numbers':
        return NumberGridContent(lessonId: lesson.id);
      case 'sentences':
      case 'cat_sentences':
      case 'seed_sentences':
        return SentenceListContent(lessonId: lesson.id);
      default:
        return VocabularyListContent(lessonId: lesson.id);
    }
  }
}

class _LessonStateScaffold extends StatelessWidget {
  const _LessonStateScaffold({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: child,
    );
  }
}

class _LessonStateMessage extends StatelessWidget {
  const _LessonStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.isDark,
    required this.onBack,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go back'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered hero summary shown inside the expanded sliver header on
/// the lesson detail screen.
class _LessonHeroSummary extends StatelessWidget {
  const _LessonHeroSummary({
    required this.lesson,
    required this.scriptMode,
    required this.buildChip,
  });

  final LessonEntity lesson;
  final String scriptMode;
  final Widget Function(IconData, String) buildChip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (secondaryLocalizedText(
              olChiki: lesson.titleOlChiki,
              latin: lesson.titleLatin,
              scriptMode: scriptMode,
            ) !=
            null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              secondaryLocalizedText(
                olChiki: lesson.titleOlChiki,
                latin: lesson.titleLatin,
                scriptMode: scriptMode,
              )!,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
                fontFamily: 'OlChiki',
              ),
            ),
          ),
        Row(
          children: [
            buildChip(Icons.timer_rounded, '${lesson.estimatedMinutes} min'),
            const SizedBox(width: 12),
            buildChip(Icons.signal_cellular_alt_rounded, 'Beginner'),
          ],
        ),
      ],
    );
  }
}

String? _getQuizIdForCategory(String? categoryId, List<QuizModel> quizzes) {
  if (categoryId == null) return null;
  final cleanId = categoryId.toLowerCase();

  // First, look for an exact match in the categoryId
  for (final q in quizzes) {
    if (q.categoryId?.toLowerCase() == cleanId) {
      return q.id;
    }
  }

  // Fallback to keyword matching
  if (cleanId.contains('alphabet')) {
    return quizzes.any((q) => q.id == 'quiz_alphabets_basics')
        ? 'quiz_alphabets_basics'
        : null;
  } else if (cleanId.contains('number')) {
    return quizzes.any((q) => q.id == 'quiz_numbers_arithmetic')
        ? 'quiz_numbers_arithmetic'
        : null;
  } else if (cleanId.contains('word') || cleanId.contains('vocab')) {
    return quizzes.any((q) => q.id == 'quiz_vocabulary_fill_blank')
        ? 'quiz_vocabulary_fill_blank'
        : null;
  }
  return null;
}

void _showCompletionSheet({
  required BuildContext context,
  required LessonEntity lesson,
  required String? quizId,
  required List<QuizModel> quizzes,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  QuizModel? quiz;
  if (quizId != null) {
    try {
      quiz = quizzes.firstWhere((q) => q.id == quizId);
    } catch (_) {
      quiz = null;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) {
      return Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -120,
            left: 0,
            right: 0,
            bottom: 0,
            child: ConfettiBurst(particleCount: 50),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F141C) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: AppColors.largeShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating trophy
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 1.seconds,
                      curve: Curves.easeInOutBack,
                    ),
                const SizedBox(height: 24),

                // Celebration text
                Text(
                  'Lesson Complete!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.pureBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Description & Stars
                Text(
                  'Amazing work! You completed this lesson and earned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Stars reward
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.duoYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.duoYellow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.duoYellow,
                        size: 22,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '+25 Stars',
                        style: TextStyle(
                          color: AppColors.duoYellowDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Primary action button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      context.pop(); // Pop current LessonDetailScreen
                      if (quizId != null) {
                        context.push('/quiz/$quizId');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      quiz != null ? 'Take ${quiz.title} Quiz' : 'Awesome!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                if (quizId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        context.pop(); // Pop current LessonDetailScreen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white70
                            : Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
