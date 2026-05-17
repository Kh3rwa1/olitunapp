import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/lesson_entity.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';
import '../../../core/widgets/parallax_hero_sliver_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

import 'widgets/dynamic_block_builder.dart';
import 'widgets/lesson_content_widgets.dart';

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
                title: Text(lesson.titleLatin),
                heroChild: _LessonHeroSummary(
                  lesson: lesson,
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
                context.pop();
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
  const _LessonHeroSummary({required this.lesson, required this.buildChip});

  final LessonEntity lesson;
  final Widget Function(IconData, String) buildChip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lesson.titleOlChiki.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              lesson.titleOlChiki,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
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
