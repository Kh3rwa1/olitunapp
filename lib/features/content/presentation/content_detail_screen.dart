import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/motion/confetti_overlay.dart';
import 'package:itun/shared/providers/content_providers.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/shared/widgets/content_hero.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_recommender.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'package:itun/features/practice/presentation/widgets/typing_practice_panel.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/interstitial_ad_manager.dart';
import 'package:itun/core/ads/rewarded_ad_manager.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';

import 'widgets/content_block_renderer.dart';
import 'widgets/content_completion_sheet.dart';
import 'widgets/content_detail_footer.dart';
import 'widgets/story_player_body.dart';
import '../../../l10n/generated/app_localizations.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final ContentKind kind;
  final String id;
  final String? lessonId;
  final int blockIndex;

  const ContentDetailScreen({
    super.key,
    required this.kind,
    required this.id,
    this.lessonId,
    this.blockIndex = 0,
  });

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

  /// One step back: pop when the lesson screen is underneath, otherwise
  /// rebuild it from the preserved lessonId instead of dropping to home.
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final lessonId = widget.lessonId;
    if (lessonId != null && lessonId.isNotEmpty) {
      context.go('/lesson/$lessonId/block/${widget.blockIndex}');
      return;
    }
    context.go('/');
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
                  AppLocalizations.of(
                    context,
                  )!.errorLoadingContent(err.toString()),
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
                  child: Text(AppLocalizations.of(context)!.retry),
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
              tooltip: 'Exit practice',
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
                  onBackPressed: _handleBack,
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
                      child: ContentBlockRenderer(
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
            child: ContentDetailFooter(
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

    // 1. Small completion acknowledgment. The real reward moved to retention:
    // mastering an item through repeated retrieval earns +10 stars in
    // Today's Review (review_session_screen). Paying 25 stars for opening a
    // screen implied mastery without evidence ("fake learning").
    await ref.read(userStatsProvider.notifier).addStars(5);

    // 1b. LEARN → memory engine: a completed word/sentence becomes a tracked
    // item (NEW → due immediately) so Today's Review picks it up.
    if (item.kind == ContentKind.word || item.kind == ContentKind.sentence) {
      try {
        await ref
            .read(reviewStoreProvider.notifier)
            .ensureIntroduced(
              itemId: item.id,
              itemType: item.kind == ContentKind.word
                  ? ReviewItemType.word
                  : ReviewItemType.sentence,
            );
      } catch (_) {
        // Scheduler must never break content completion.
      }
    }

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

    // 5. Show premium celebration sheet with a quiz CTA when available. The
    // interstitial waits until the learner leaves the sheet, so it never
    // covers the celebration itself.
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

  Future<void> _showLessonCompleteInterstitial() => ref
      .read(interstitialAdManagerProvider)
      .showIfAllowed(context, 'lesson_complete');

  void _showCompletionSheet(
    BuildContext context,
    ContentItem item, {
    LessonQuizRecommendation? recommendation,
  }) {
    unawaited(
      showContentCompletionSheet(
        context,
        recommendation: recommendation,
        onStartQuiz: (quizId) async {
          await _showLessonCompleteInterstitial();
          if (mounted) this.context.push('/quiz/$quizId');
        },
        // Same one-step-back rule as the header back button.
        onStepBack: () async {
          await _showLessonCompleteInterstitial();
          if (mounted) _handleBack();
        },
        bonusAction: ref.read(adStateProvider).shouldShowAds
            ? _LessonBonusStarsButton(outerContext: context)
            : null,
      ),
    );
  }
}

/// Opt-in rewarded ad on the lesson completion sheet (+50 stars).
class _LessonBonusStarsButton extends ConsumerStatefulWidget {
  final BuildContext outerContext;

  const _LessonBonusStarsButton({required this.outerContext});

  @override
  ConsumerState<_LessonBonusStarsButton> createState() =>
      _LessonBonusStarsButtonState();
}

class _LessonBonusStarsButtonState
    extends ConsumerState<_LessonBonusStarsButton> {
  bool _claimed = false;

  void _snack(String message, {Color? color}) {
    final outer = widget.outerContext;
    if (!outer.mounted) return;
    ScaffoldMessenger.of(outer).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_claimed) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final shown = await ref
              .read(rewardedAdManagerProvider)
              .show(
                context: context,
                placement: 'lesson_complete_bonus_stars',
                rewardType: RewardType.stars,
                amount: 50,
                onRewardGranted: () {
                  if (mounted) setState(() => _claimed = true);
                  _snack(l10n.bonusStarsEarned, color: AppColors.success);
                },
              );
          if (!shown) _snack(l10n.rewardedAdCooldown);
        },
        icon: const Icon(
          Icons.stars_rounded,
          color: AppColors.accentGoldDark,
          size: 22,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.watchAdBonusStars,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGoldDark,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accentGoldDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
