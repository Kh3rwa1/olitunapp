// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/motion/confetti_overlay.dart';
import 'package:itun/core/audio/audio_service.dart';
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
import 'package:itun/features/rhymes/presentation/providers/rhyme_audio_provider.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:itun/features/rhymes/presentation/widgets/enchanted_visualizer.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/features/rhymes/presentation/widgets/cover_hero.dart';

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
  int _activeSubTab = 0; // 0 = Lyrics, 1 = Vocab, 2 = Cultural Notes
  late final ScrollController _lyricScrollController;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _lyricScrollController = ScrollController();
    // For kinds other than letter or number, tracing is marked completed by default
    if (widget.kind != ContentKind.letter &&
        widget.kind != ContentKind.number) {
      _isTracingCompleted = true;
    }
  }

  @override
  void dispose() {
    _lyricScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      contentDetailProvider((widget.kind, widget.id)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = AppColors.primary; // Olitun signature emerald green

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
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
    // 0. Redirect for premium rhyme player
    if (item.kind == ContentKind.rhyme) {
      return _buildPremiumBakhedBody(context, item, isDark, accentColor);
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
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
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

    return Stack(
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildBlockRenderer(
                      context,
                      block,
                      accentColor,
                      isDark,
                    ),
                  );
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
          child: _buildFooter(context, item, accentColor, isDark),
        ),

        // Completion celebration overlay
        if (_isFinished)
          const Positioned.fill(
            child: AbsorbPointer(child: ConfettiBurst(particleCount: 70)),
          ),
      ],
    );
  }

  Widget _buildBlockRenderer(
    BuildContext context,
    ContentBlock block,
    Color accentColor,
    bool isDark,
  ) {
    switch (block.type) {
      case 'text':
        final textBlock = block as TextBlock;
        return MarkdownBody(
          data: textBlock.markdown,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
            h1: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            h2: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        );

      case 'image':
        final imageBlock = block as ImageBlock;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageBlock.media.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
            ),
            if (imageBlock.caption != null) ...[
              const SizedBox(height: 8),
              Text(
                imageBlock.caption!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );

      case 'video':
        final videoBlock = block as VideoBlock;
        // Re-use standard full bleed visual renderer or embed inline player
        return _InlineVideoPlayer(media: videoBlock.media);

      case 'audio':
        final audioBlock = block as AudioBlock;
        return _InlineAudioPlayer(
          media: audioBlock.media,
          transcript: audioBlock.transcript,
          isDark: isDark,
        );

      case 'lottie':
        final lottieBlock = block as LottieBlock;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LottieDisplay(
            url: lottieBlock.media.url,
            repeat: lottieBlock.loop,
            height: 240,
          ),
        );

      case 'quiz':
        final quizBlock = block as QuizBlock;
        return ScaleButton(
          onPressed: () => context.push('/quiz/${quizBlock.quizId}'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take a Quiz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Test your knowledge now!',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        );

      case 'glyph':
        final glyphBlock = block as GlyphBlock;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(
                glyphBlock.olChiki,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontFamily: 'OlChiki',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                glyphBlock.latin,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (glyphBlock.audioUrl != null) ...[
                const SizedBox(height: 16),
                IconButton.filled(
                  icon: const Icon(Icons.volume_up_rounded),
                  style: IconButton.styleFrom(backgroundColor: accentColor),
                  onPressed: () => ref
                      .read(audioServiceProvider)
                      .playUrl(glyphBlock.audioUrl!),
                ),
              ],
            ],
          ),
        );

      case 'callout':
        final calloutBlock = block as CalloutBlock;
        final infoColor = _getCalloutColor(calloutBlock.variant);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: infoColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: infoColor.withOpacity(0.25), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getCalloutIcon(calloutBlock.variant),
                color: infoColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  calloutBlock.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'tracing':
        final tracingBlock = block as TracingBlock;
        return TracingCanvas(
          config: tracingBlock.config,
          accentColor: accentColor,
          onCompleted: (count) {
            if (count >= tracingBlock.config.requiredCompletions) {
              setState(() {
                _isTracingCompleted = true;
              });
            }
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(
    BuildContext context,
    ContentItem item,
    Color accentColor,
    bool isDark,
  ) {
    final settings = ref.watch(typingPracticeSettingsProvider);
    final bool isEligible =
        settings.enabled &&
        (item.kind == ContentKind.word || item.kind == ContentKind.sentence) &&
        item.olChiki != null &&
        item.olChiki!.isNotEmpty &&
        item.olChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    if (isEligible) {
      final typingPracticeArgs = TypingPracticeArgs(
        itemKey: item.id,
        target: item.olChiki!,
        latin: item.title,
        meaning: item.subtitle ?? '',
        contentType: item.kind == ContentKind.word ? 'word' : 'sentence',
      );
      final typingState = ref.watch(
        typingPracticeControllerProvider(typingPracticeArgs),
      );

      if (typingState.phase == TypingPhase.idle) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F141C) : Colors.white)
                .withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (item.effectiveAudioUrl != null) ...[
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    color: AppColors.primary,
                    onPressed: () {
                      ref
                          .read(audioServiceProvider)
                          .playUrl(item.effectiveAudioUrl!);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(
                              typingPracticeControllerProvider(
                                typingPracticeArgs,
                              ).notifier,
                            )
                            .startPractice();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_outlined,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Practice Typing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F141C) : Colors.white).withOpacity(
          0.85,
        ),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isTracingCompleted
                ? () => unawaited(_onCompleteContent(item))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              _isTracingCompleted
                  ? Icons.check_circle_outline
                  : Icons.gesture_rounded,
            ),
            label: Text(
              _isTracingCompleted
                  ? 'Finish Practice (+25 stars)'
                  : 'Complete Tracing Exercise first',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
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

    // 5. Show premium celebration sheet with a quiz CTA when available.
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
            color: isDark ? const Color(0xFF0F141C) : Colors.white,
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
                      foregroundColor: Colors.white,
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

  Color _getCalloutColor(CalloutVariant variant) {
    switch (variant) {
      case CalloutVariant.tip:
        return const Color(0xFF10B981); // Green
      case CalloutVariant.warning:
        return const Color(0xFFEF4444); // Red
      case CalloutVariant.note:
        return const Color(0xFF3B82F6); // Blue
      case CalloutVariant.success:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  IconData _getCalloutIcon(CalloutVariant variant) {
    switch (variant) {
      case CalloutVariant.tip:
        return Icons.lightbulb_outline_rounded;
      case CalloutVariant.warning:
        return Icons.warning_amber_rounded;
      case CalloutVariant.note:
        return Icons.info_outline_rounded;
      case CalloutVariant.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  // ============== PREMIUM BAKHED AUDIO PLAYER & LEARNING HUB ==============

  Widget _buildPremiumBakhedBody(
    BuildContext context,
    ContentItem item,
    bool isDark,
    Color accentColor,
  ) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isPlaying =
        audioState.playingRhymeId == item.id && audioState.isPlaying;

    final durationMs = audioState.duration.inMilliseconds;
    final positionMs = audioState.position.inMilliseconds;

    // Fetch synced learning content
    final learningContentAsync = ref.watch(
      bakhedLearningContentProvider(item.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070B13), // Deep premium midnight black
      body: Stack(
        children: [
          // Ambient blurred accent background
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.12),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom glassy top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.maybePop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (item.subtitle != null &&
                                item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cover Art & Visualizer Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.18),
                            blurRadius: 36,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Thumbnail / Cover Art Image / Video Autoplay
                            CoverHero(
                              media: item.heroMedia,
                              coverMediaType: item.coverMediaType,
                              fallback: Container(
                                color: const Color(0xFF151C2A),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 64,
                                  color: accentColor,
                                ),
                              ),
                            ),

                            // Visualizer Overlay
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: TickerMode(
                                enabled: isPlaying,
                                child: EnchantedVisualizer(
                                  isPlaying: isPlaying,
                                  color: Colors.white.withOpacity(0.25),
                                  height: 80,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Audio Progress Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.12),
                      thumbColor: Colors.white,
                      trackHeight: 4,
                      overlayColor: accentColor.withOpacity(0.16),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      max: durationMs > 0 ? durationMs.toDouble() : 100.0,
                      value: positionMs.toDouble().clamp(
                        0.0,
                        durationMs > 0 ? durationMs.toDouble() : 100.0,
                      ),
                      onChanged: (val) {
                        ref
                            .read(rhymeAudioProvider.notifier)
                            .seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),

                // Timestamps Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(milliseconds: positionMs)),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(Duration(milliseconds: durationMs)),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Audio Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Replay 10s
                      IconButton(
                        icon: Icon(
                          Icons.replay_10_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final pos = Duration(milliseconds: positionMs);
                          final target = pos - const Duration(seconds: 10);
                          ref
                              .read(rhymeAudioProvider.notifier)
                              .seek(
                                target < Duration.zero ? Duration.zero : target,
                              );
                        },
                      ),
                      const SizedBox(width: 24),
                      // Grand Play/Pause Circle
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(rhymeAudioProvider.notifier)
                              .togglePlay(
                                item.id,
                                item.effectiveAudioUrl,
                                title: item.title,
                                artworkUrl: item.heroMedia?.url,
                              );
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                            color: const Color(0xFF0A0E15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Forward 10s
                      IconButton(
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final pos = Duration(milliseconds: positionMs);
                          final dur = Duration(milliseconds: durationMs);
                          final target = pos + const Duration(seconds: 10);
                          ref
                              .read(rhymeAudioProvider.notifier)
                              .seek(target > dur ? dur : target);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Glassy Learning Sub-Tabs Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSubTabButton(
                            0,
                            Icons.lyrics_rounded,
                            'Lyrics',
                          ),
                        ),
                        Expanded(
                          child: _buildSubTabButton(
                            1,
                            Icons.menu_book_rounded,
                            'Vocabulary',
                          ),
                        ),
                        Expanded(
                          child: _buildSubTabButton(
                            2,
                            Icons.auto_stories_rounded,
                            'Notes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scrolling Content Panel
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    child: learningContentAsync.when(
                      data: (content) {
                        return _buildActiveSubTabContent(
                          content,
                          item,
                          isPlaying,
                          positionMs,
                          accentColor,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Error loading details: $err',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, IconData icon, String label) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _activeSubTab = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.12))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubTabContent(
    BakhedLearningContent content,
    ContentItem item,
    bool isPlaying,
    int positionMs,
    Color accentColor,
  ) {
    switch (_activeSubTab) {
      case 0:
        return _buildSyncedLyrics(
          content.lyrics,
          item,
          positionMs,
          accentColor,
        );
      case 1:
        return _buildVocabularyList(content.vocabulary, accentColor);
      case 2:
        return _buildCulturalNotes(content.culturalNotes);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSyncedLyrics(
    List<BakhedLyricLine> lyrics,
    ContentItem item,
    int positionMs,
    Color accentColor,
  ) {
    if (lyrics.isEmpty) {
      // Fallback: render the item's standard blocks (e.g. text/translation) in a premium way
      final textBlocks = item.blocks.whereType<TextBlock>().toList();
      if (textBlocks.isEmpty) {
        return Center(
          child: Text(
            'Lyrics are being added.',
            style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: textBlocks.length,
        itemBuilder: (context, index) {
          final block = textBlocks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.textOlChiki != null &&
                    block.textOlChiki!.isNotEmpty) ...[
                  Text(
                    block.textOlChiki!,
                    style: const TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  block.textLatin ?? block.markdown,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Find the active lyric line index
    int activeIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      if (positionMs >= line.startMs && positionMs <= line.endMs) {
        activeIndex = i;
        break;
      }
    }
    if (activeIndex == -1) {
      for (int i = lyrics.length - 1; i >= 0; i--) {
        if (positionMs >= lyrics[i].endMs) {
          activeIndex = i;
          break;
        }
      }
    }

    // Smooth auto-scroll to center
    if (activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_lyricScrollController.hasClients && activeIndex >= 0) {
          final targetOffset = (activeIndex * 105.0) - 100.0;
          _lyricScrollController.animateTo(
            targetOffset.clamp(
              0.0,
              _lyricScrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    return ListView.builder(
      controller: _lyricScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == activeIndex;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref
                .read(rhymeAudioProvider.notifier)
                .seek(Duration(milliseconds: line.startMs));
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isActive ? 1.0 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 24.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isActive
                    ? Border.all(color: Colors.white.withOpacity(0.05))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.olChiki,
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: isActive ? 26 : 23,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line.latin,
                    style: GoogleFonts.inter(
                      fontSize: isActive ? 16 : 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  if (line.meaning.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      line.meaning,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVocabularyList(
    List<BakhedVocabularyItem> vocabulary,
    Color accentColor,
  ) {
    if (vocabulary.isEmpty) {
      return Center(
        child: Text(
          'No vocabulary items defined.',
          style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: vocabulary.length,
      itemBuilder: (context, index) {
        final item = vocabulary[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.olChiki,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.latin,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (item.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.meaning,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.audioFileId.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: accentColor),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final db = ref.read(appwriteDbServiceProvider);
                      final url = db.getFileViewUrl('audio', item.audioFileId);
                      ref.read(audioServiceProvider).playUrl(url);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCulturalNotes(List<BakhedCulturalNote> notes) {
    final publishedNotes = notes.where((n) => n.isPublished).toList();
    if (publishedNotes.isEmpty) {
      return Center(
        child: Text(
          'Cultural notes are being prepared.',
          style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: publishedNotes.length,
      itemBuilder: (context, index) {
        final note = publishedNotes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_added_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: note.body,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              if (note.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),
                Text(
                  'Source: ${note.source}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Inline video player adapter
class _InlineVideoPlayer extends StatefulWidget {
  final ContentMedia media;

  const _InlineVideoPlayer({required this.media});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            if (widget.media.posterUrl == null) {
              _controller!.play();
              _isPlaying = true;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_initialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPlaying) {
                      _controller!.pause();
                      _isPlaying = false;
                    } else {
                      _controller!.play();
                      _isPlaying = true;
                    }
                  });
                },
                child: VideoPlayer(_controller!),
              ),
              if (!_isPlaying)
                Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.play();
                        _isPlaying = true;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Inline audio player adapter
class _InlineAudioPlayer extends StatefulWidget {
  final ContentMedia media;
  final String? transcript;
  final bool isDark;

  const _InlineAudioPlayer({
    required this.media,
    this.transcript,
    required this.isDark,
  });

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  // Simple custom mini audio player using standard flutter/audioplayers or direct Ref interaction
  // We will re-use ref.read(audioServiceProvider) to keep it lightweight!
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () async {
                      if (_isPlaying) {
                        await ref.read(audioServiceProvider).stop();
                        setState(() => _isPlaying = false);
                      } else {
                        await ref
                            .read(audioServiceProvider)
                            .playUrl(widget.media.url);
                        setState(() => _isPlaying = true);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPlaying
                              ? 'Playing Audio Pronunciation'
                              : 'Listen to audio instruction',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.media.durationSeconds != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Duration: ${widget.media.durationSeconds}s',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.transcript != null &&
                  widget.transcript!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  widget.transcript!,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
