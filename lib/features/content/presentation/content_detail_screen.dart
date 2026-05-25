// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/motion/confetti_overlay.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/shared/widgets/content_hero.dart';
import 'package:itun/shared/widgets/tracing_canvas.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/core/presentation/animations/scale_button.dart';

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
    // 1. Resolve content blocks
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
          child: Lottie.network(
            lottieBlock.media.url,
            repeat: lottieBlock.loop,
            height: 240,
            fit: BoxFit.contain,
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
                ? () => _onCompleteContent(item)
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

  void _onCompleteContent(ContentItem item) {
    // 1. Award stars
    ref.read(userStatsProvider.notifier).addStars(25);

    // 2. Set completed today
    ref.read(lessonCompletedTodayProvider.notifier).setCompleted(true);

    // 3. Set lesson completed (for analytics and progress)
    ref
        .read(userStatsProvider.notifier)
        .completeLesson(
          item.id,
          categoryId: item.categoryId,
          estimatedMinutes: 2,
        );

    // 4. Trigger celebration
    setState(() {
      _isFinished = true;
    });

    // 5. Show premium celebration sheet
    _showCompletionSheet(context, item);
  }

  void _showCompletionSheet(BuildContext context, ContentItem item) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                'Practice Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Superb! You finished this module successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Close sheet and go back
                    Navigator.pop(context); // close sheet
                    Navigator.maybePop(this.context); // close detail screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Lessons',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
