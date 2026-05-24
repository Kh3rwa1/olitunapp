import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/widgets/state_widgets.dart';
import '../../home/presentation/providers/mission_providers.dart';

import 'widgets/dynamic_block_builder.dart';
import 'widgets/lesson_content_widgets.dart';
import '../../../core/motion/confetti_overlay.dart';

bool get _isTesting {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  bool _isScrollCompleted = false;
  String? _trackedStartedLessonId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    double progress = 0.0;
    if (maxScroll > 0) {
      progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    } else {
      progress = 1.0;
    }

    _scrollProgress.value = progress;

    if (progress >= 0.90 && !_isScrollCompleted) {
      setState(() {
        _isScrollCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonNotifierProvider);

    // Watch content providers to ensure data is available for dynamic block matching.
    ref.watch(lettersProvider);
    ref.watch(numbersProvider);
    ref.watch(wordsProvider);
    ref.watch(sentencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lessons.when(
      loading: () =>
          const Scaffold(body: AppLoadingState(type: AppLoadingType.page)),
      error: (e, s) => Scaffold(
        body: AppErrorState(
          message: 'Could not load this lesson.',
          onRetry: () => ref.read(lessonNotifierProvider.notifier).refresh(),
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return Scaffold(
            body: AppEmptyState(
              title: 'No lessons available',
              description: 'New learning content will appear here soon.',
              buttonText: 'Back to Home',
              onButtonPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              icon: Icons.school_outlined,
            ),
          );
        }

        final lesson = _findLesson(data, widget.lessonId);
        if (lesson == null) {
          return Scaffold(
            body: AppEmptyState(
              title: 'Lesson not found',
              description: 'This lesson may have been moved or removed.',
              buttonText: 'Back to Home',
              onButtonPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              icon: Icons.search_off_rounded,
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
        if (_trackedStartedLessonId != lesson.id) {
          _trackedStartedLessonId = lesson.id;
          unawaited(
            ref
                .read(lessonNotifierProvider.notifier)
                .trackLessonStarted(
                  lesson,
                  alreadyCompleted: completedLessons.contains(lesson.id),
                  scriptMode: scriptMode,
                ),
          );
        }
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          body: Stack(
            children: [
              NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.maxScrollExtent == 0 && !_isScrollCompleted) {
                    Future.microtask(() {
                      if (mounted) {
                        setState(() {
                          _isScrollCompleted = true;
                          _scrollProgress.value = 1.0;
                        });
                      }
                    });
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scrollController,
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
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      actions: [
                        Consumer(
                          builder: (context, ref, _) {
                            final layoutMode = ref.watch(
                              lessonLayoutModeProvider,
                            );
                            final isGrid = layoutMode == LessonLayoutMode.grid;

                            return IconButton(
                              icon: Icon(
                                isGrid
                                    ? Icons.view_list_rounded
                                    : Icons.grid_view_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                updateLessonLayoutMode(
                                  ref,
                                  isGrid
                                      ? LessonLayoutMode.list
                                      : LessonLayoutMode.grid,
                                );
                              },
                              tooltip: isGrid
                                  ? 'Switch to List View'
                                  : 'Switch to Bento Grid View',
                            );
                          },
                        ),
                      ],
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
              ),
              const Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: OfflineStatusBanner(),
              ),
            ],
          ),
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F141C) : Colors.white)
                      .withValues(alpha: 0.85),
                  border: Border(
                    top: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.08,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isScrollCompleted
                        ? () {
                            final notifier = ref.read(
                              userStatsProvider.notifier,
                            );
                            notifier.completeLesson(
                              lesson.id,
                              categoryId: lesson.categoryId,
                              estimatedMinutes: lesson.estimatedMinutes,
                            );
                            notifier.addStars(25);
                            ref
                                .read(lessonCompletedTodayProvider.notifier)
                                .setCompleted(true);

                            final quizzes =
                                ref.read(quizzesProvider).value ?? [];
                            final quizId = _getQuizIdForCategory(
                              lesson.categoryId,
                              lesson.id,
                              quizzes,
                            );

                            // Find next lesson to allow routing!
                            final currentIdx = data.indexOf(lesson);
                            final nextLessonId =
                                (currentIdx != -1 &&
                                    currentIdx + 1 < data.length)
                                ? data[currentIdx + 1].id
                                : null;

                            _showCompletionSheet(
                              context: context,
                              lesson: lesson,
                              quizId: quizId,
                              quizzes: quizzes,
                              nextLessonId: nextLessonId,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScrollCompleted
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      foregroundColor: _isScrollCompleted
                          ? Colors.white
                          : (isDark ? Colors.white30 : Colors.black38),
                      elevation: _isScrollCompleted ? 2 : 0,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.check_circle_rounded,
                      color: _isScrollCompleted
                          ? Colors.white
                          : (isDark ? Colors.white30 : Colors.black38),
                    ),
                    label: Text(
                      _isScrollCompleted
                          ? 'Complete Lesson'
                          : 'Finish the lesson to complete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _isScrollCompleted
                            ? Colors.white
                            : (isDark ? Colors.white30 : Colors.black38),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    final cleanCategory = lesson.categoryId.toLowerCase();
    final isAlphabet =
        cleanCategory.contains('alphabet') || cleanCategory.contains('letter');
    final isNumber = cleanCategory.contains('number');
    final isSentence =
        cleanCategory.contains('sentence') || cleanCategory.contains('phrase');

    final layoutMode = ref.watch(lessonLayoutModeProvider);

    if (layoutMode == LessonLayoutMode.grid) {
      if (lesson.blocks.isNotEmpty) {
        // Find intro/explanatory blocks (text longer than 3 characters is a general description, not a single letter/numeral)
        final introBlocks = lesson.blocks.where((block) {
          final text = block.textOlChiki?.trim() ?? '';
          if (text.isEmpty) return true;
          return (isAlphabet || isNumber) ? text.length > 3 : false;
        }).toList();

        final gridBlocks = lesson.blocks.where((block) {
          final text = block.textOlChiki?.trim() ?? '';
          if (text.isEmpty) return false;
          return (isAlphabet || isNumber) ? text.length <= 3 : true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (introBlocks.isNotEmpty) ...[
              ...introBlocks.map(
                (block) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: DynamicBlockBuilder(lessonId: lesson.id, block: block),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (gridBlocks.isNotEmpty)
              BlockGridContent(
                lessonId: lesson.id,
                blocks: gridBlocks,
                categoryId: lesson.categoryId,
              ),
          ],
        );
      }

      // Fallback to provider-based lists if blocks are empty
      if (isAlphabet) {
        return LetterGridContent(lessonId: lesson.id);
      } else if (isNumber) {
        return NumberGridContent(lessonId: lesson.id);
      } else if (isSentence) {
        return SentenceListContent(lessonId: lesson.id);
      } else {
        return VocabularyListContent(lessonId: lesson.id);
      }
    } else {
      // Fall back to original list view of text blocks!
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

      // Fallback to provider-based lists
      if (isAlphabet) {
        return LetterGridContent(lessonId: lesson.id);
      } else if (isNumber) {
        return NumberGridContent(lessonId: lesson.id);
      } else if (isSentence) {
        return SentenceListContent(lessonId: lesson.id);
      } else {
        return VocabularyListContent(lessonId: lesson.id);
      }
    }
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

String? _getQuizIdForCategory(
  String? categoryId,
  String? lessonId,
  List<QuizModel> quizzes,
) {
  if (lessonId != null) {
    final cleanLessonId = lessonId.toLowerCase();

    // 1. Vocabulary dynamic quizzes matching
    if (cleanLessonId.startsWith('lesson_vocab_')) {
      final suffix = cleanLessonId.replaceFirst('lesson_vocab_', '');
      final possibleQuizId = 'quiz_dynamic_vocab_$suffix';
      if (quizzes.any((q) => q.id == possibleQuizId)) {
        return possibleQuizId;
      }

      // Fallback hybrid matching for non-standard vocab subcategories
      if (suffix.contains('beginner')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_beginner')
            ? 'quiz_dynamic_hybrid_beginner'
            : null;
      } else if (suffix.contains('intermediate') ||
          suffix.contains('conversational')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_intermediate')
            ? 'quiz_dynamic_hybrid_intermediate'
            : null;
      } else if (suffix.contains('advanced') || suffix.contains('folk')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_advanced')
            ? 'quiz_dynamic_hybrid_advanced'
            : null;
      }
    }

    // 2. Sentences dynamic quizzes matching
    if (cleanLessonId.startsWith('lesson_sentences_')) {
      final suffix = cleanLessonId.replaceFirst('lesson_sentences_', '');
      final possibleQuizId = 'quiz_dynamic_sentences_$suffix';
      if (quizzes.any((q) => q.id == possibleQuizId)) {
        return possibleQuizId;
      }

      // Fallback hybrid matching for non-standard sentence subcategories
      if (suffix.contains('beginner')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_beginner')
            ? 'quiz_dynamic_hybrid_beginner'
            : null;
      } else if (suffix.contains('intermediate') ||
          suffix.contains('conversational')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_intermediate')
            ? 'quiz_dynamic_hybrid_intermediate'
            : null;
      } else if (suffix.contains('advanced') || suffix.contains('folk')) {
        return quizzes.any((q) => q.id == 'quiz_dynamic_hybrid_advanced')
            ? 'quiz_dynamic_hybrid_advanced'
            : null;
      }
    }
  }

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
  required String? nextLessonId,
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

  Widget buildBentoCard({
    required Widget child,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final reduceEffects = ref.watch(reduceVisualEffectsProvider);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
                    Builder(
                      builder: (context) {
                        final trophy = Container(
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
                        );
                        if (reduceEffects || _isTesting) {
                          return trophy;
                        }
                        return trophy
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.1, 1.1),
                              duration: 1.seconds,
                              curve: Curves.easeInOutBack,
                            );
                      },
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

                    // Description
                    Text(
                      'Amazing work! You completed this lesson and earned',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bento grid row
                    Row(
                      children: [
                        // Stars Bento
                        Expanded(
                          child: buildBentoCard(
                            backgroundColor: AppColors.duoYellow.withValues(
                              alpha: 0.12,
                            ),
                            borderColor: AppColors.duoYellow.withValues(
                              alpha: 0.25,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.duoYellow,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Stars Earned',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '+25 Stars',
                                  style: TextStyle(
                                    color: AppColors.duoYellowDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Progress Bento
                        Expanded(
                          child: buildBentoCard(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderColor: AppColors.primary.withValues(
                              alpha: 0.25,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Scroll Depth',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '100% Done',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.brandTextDark
                                        : AppColors.brandTextLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Full-width Bottom Bento
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: isDark
                                    ? AppColors.brandTextDark
                                    : AppColors.brandTextLight,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Santali Mastery',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.brandTextDark
                                      : AppColors.brandTextLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You are officially on your way to mastering Ol Chiki! Laha se!',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext); // Close sheet
                          if (quizId != null) {
                            context.pushReplacement('/quiz/$quizId');
                          } else if (nextLessonId != null) {
                            context.pushReplacement('/lesson/$nextLessonId');
                          } else {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
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
                          quiz != null
                              ? 'Take ${quiz.title ?? 'Quiz'}'
                              : (nextLessonId != null
                                    ? 'Next Lesson'
                                    : 'Johar (Finish)'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    // Secondary action buttons
                    if (quizId != null || nextLessonId != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (quizId != null && nextLessonId != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  context.pushReplacement(
                                    '/lesson/$nextLessonId',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Next Lesson',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white60
                                    : Colors.black54,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
