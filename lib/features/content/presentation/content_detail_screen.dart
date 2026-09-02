// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/motion/confetti_overlay.dart';
import 'package:itun/shared/providers/content_providers.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/shared/widgets/content_hero.dart';
import 'package:itun/shared/widgets/tracing_canvas.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_recommender.dart';
import 'package:itun/core/presentation/animations/scale_button.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';
import 'package:itun/shared/widgets/lottie_display.dart';
import 'package:itun/features/practice/presentation/widgets/typing_practice_panel.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';
import 'package:itun/core/ads/interstitial_ad_manager.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';

import 'providers/audio_playback_providers.dart';
import 'widgets/audio_controls_bar.dart';
import 'widgets/inline_media_players.dart';
import 'widgets/story_player_body.dart';

part 'widgets/content_detail_sections.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final ContentKind kind;
  final String id;

  const ContentDetailScreen({super.key, required this.kind, required this.id});

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  bool _isTracingCompleted = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // For kinds other than letter or number, tracing is marked completed by default
    if (widget.kind != ContentKind.letter &&
        widget.kind != ContentKind.number) {
      _isTracingCompleted = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _markTracingCompleted() {
    setState(() {
      _isTracingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      contentDetailProvider((widget.kind, widget.id)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = AppColors.primary; // Olitun signature emerald green

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      body: detailAsync.when(
        data: (item) => _buildContentBody(context, item, isDark, accentColor),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading content: $err',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    contentDetailProvider((widget.kind, widget.id)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(
    BuildContext context,
    ContentItem item,
    bool isDark,
    Color accentColor,
  ) {
    // 0. Segment-based story player for rhymes/stories. Falls back to
    // the premium body when the multilingual-audio flag is off, the
    // fetch errors, or the item has no `story_segments` rows — so the
    // existing experience never regresses (spec §27).
    if (item.kind == ContentKind.rhyme) {
      return StoryPlayerBody(item: item, accentColor: accentColor);
    }

    // 1. Check if eligible for typing practice
    final settings = ref.watch(typingPracticeSettingsProvider);
    final bool isEligible =
        settings.enabled &&
        (item.kind == ContentKind.word || item.kind == ContentKind.sentence) &&
        item.olChiki != null &&
        item.olChiki!.isNotEmpty &&
        item.olChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    final typingPracticeArgs = isEligible
        ? TypingPracticeArgs(
            itemKey: item.id,
            target: item.olChiki!,
            latin: item.title,
            meaning: item.subtitle ?? '',
            contentType: item.kind == ContentKind.word ? 'word' : 'sentence',
          )
        : null;

    final typingState = isEligible && typingPracticeArgs != null
        ? ref.watch(typingPracticeControllerProvider(typingPracticeArgs))
        : null;

    if (isEligible && typingState != null && typingPracticeArgs != null) {
      if (typingState.phase != TypingPhase.idle) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                ref
                    .read(
                      typingPracticeControllerProvider(
                        typingPracticeArgs,
                      ).notifier,
                    )
                    .tryAgain();
              },
            ),
            title: Text(
              item.kind == ContentKind.word
                  ? 'Practice Word'
                  : 'Practice Sentence',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TypingPracticePanel(
                args: typingPracticeArgs,
                audioUrl: item.effectiveAudioUrl,
              ),
            ),
          ),
        );
      }
    }

    // 2. Resolve content blocks
    final List<ContentBlock> blocks = [...item.blocks];

    // 2. Auto-inject tracing config if kind requires it and not explicitly added
    if ((item.kind == ContentKind.letter || item.kind == ContentKind.number) &&
        !blocks.any((b) => b is TracingBlock) &&
        item.tracing != null) {
      blocks.insert(
        0,
        TracingBlock(
          id: 'auto-tracing-${item.id}',
          order: -1,
          config: item.tracing!,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      bottomNavigationBar: const BannerAdWidget(
        placement: 'content_detail_bottom',
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sliver Header
              SliverToBoxAdapter(
                child: ContentHero(
                  item: item,
                  accentColor: accentColor,
                  onBackPressed: () => Navigator.maybePop(context),
                ),
              ),

              // Blocks list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final block = blocks[index];
                    final blockWidget = Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _ContentBlockRenderer(
                        item: item,
                        block: block,
                        accentColor: accentColor,
                        isDark: isDark,
                        onTracingCompleted: _markTracingCompleted,
                      ),
                    );

                    if (index == 1 && blocks.length > 2) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          blockWidget,
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: RepaintBoundary(
                              child: NativeAdWidget(
                                placement: 'content_detail_inline',
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return blockWidget;
                  }, childCount: blocks.length),
                ),
              ),
            ],
          ),

          // Bottom progress footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ContentDetailFooter(
              item: item,
              accentColor: accentColor,
              isDark: isDark,
              isTracingCompleted: _isTracingCompleted,
              onCompleteContent: _onCompleteContent,
            ),
          ),

          // Completion celebration overlay
          if (_isFinished)
            const Positioned.fill(
              child: AbsorbPointer(child: ConfettiBurst(particleCount: 70)),
            ),
        ],
      ),
    );
  }

  Future<void> _onCompleteContent(ContentItem item) async {
    if (_isFinished) return;

    final recommendation = _recommendedQuizFor(item);

    // 1. Award stars
    await ref.read(userStatsProvider.notifier).addStars(25);

    // 2. Set completed today
    ref.read(lessonCompletedTodayProvider.notifier).setCompleted(true);

    // 3. Set lesson completed (for analytics and progress)
    await ref
        .read(userStatsProvider.notifier)
        .completeLesson(
          item.id,
          categoryId: item.categoryId,
          estimatedMinutes: 2,
        );

    // 4. Trigger celebration
    if (!mounted) return;
    setState(() {
      _isFinished = true;
    });

    // 5. Trigger interstitial ad if allowed (free tier, frequency cap checked)
    unawaited(
      ref
          .read(interstitialAdManagerProvider)
          .showIfAllowed(context, 'lesson_complete'),
    );

    // 6. Show premium celebration sheet with a quiz CTA when available.
    _showCompletionSheet(context, item, recommendation: recommendation);
  }

  LessonQuizRecommendation? _recommendedQuizFor(ContentItem item) {
    final quizzes =
        ref.read(quizzesProvider).valueOrNull ?? const <QuizModel>[];
    return LessonQuizRecommender.recommend(
      lesson: item,
      quizzes: quizzes,
      stats: ref.read(userStatsProvider).valueOrNull,
    );
  }

  void _showCompletionSheet(
    BuildContext context,
    ContentItem item, {
    LessonQuizRecommendation? recommendation,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final recommendedQuiz = recommendation?.quiz;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.quizDarkCardAlt : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: AppColors.largeShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                recommendedQuiz == null
                    ? 'Practice Complete!'
                    : 'Ready for a Quiz?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendedQuiz == null
                    ? 'Superb! You finished this module successfully.'
                    : recommendation!.isRetake
                    ? 'Nice work. Retake "${recommendedQuiz.title ?? 'this quiz'}" now to sharpen your score.'
                    : 'Great finish. Start "${recommendedQuiz.title ?? 'this quiz'}" now while the lesson is fresh.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              if (recommendation != null) ...[
                const SizedBox(height: 10),
                Text(
                  recommendation.reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (recommendedQuiz != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push('/quiz/${recommendedQuiz.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // Close sheet and go back
                    Navigator.pop(sheetContext); // close sheet
                    Navigator.maybePop(this.context); // close detail screen
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    recommendedQuiz == null ? 'Back to Lessons' : 'Maybe Later',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============== PREMIUM BAKHED AUDIO PLAYER & LEARNING HUB ==============
}

// Inline video player adapter
