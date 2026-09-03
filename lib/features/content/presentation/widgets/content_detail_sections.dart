// ignore_for_file: deprecated_member_use
part of '../content_detail_screen.dart';

// Renders a single ContentBlock (text/image/video/audio/lottie/quiz/
// glyph/callout/tracing) inside the content detail scroll view.
class _ContentBlockRenderer extends ConsumerWidget {
  const _ContentBlockRenderer({
    required this.item,
    required this.block,
    required this.accentColor,
    required this.isDark,
    required this.onTracingCompleted,
  });

  final ContentItem item;
  final ContentBlock block;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTracingCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (block.type) {
      case 'text':
        final textBlock = block as TextBlock;
        return MarkdownBody(
          data: textBlock.markdown,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? AppColors.lightBorder : AppColors.darkBorder,
            ),
            h1: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkSurfaceElevated,
            ),
            h2: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppColors.darkBorder,
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
                memCacheWidth: 1080,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceVariant,
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
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );

      case 'video':
        final videoBlock = block as VideoBlock;
        // Re-use standard full bleed visual renderer or embed inline player
        return InlineVideoPlayer(media: videoBlock.media);

      case 'audio':
        final audioBlock = block as AudioBlock;
        return InlineAudioPlayer(
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
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                  color: isDark ? Colors.white : AppColors.darkSurfaceElevated,
                ),
              ),
              if (glyphBlock.audioUrl != null) ...[
                const SizedBox(height: 16),
                IconButton.filled(
                  icon: const Icon(Icons.volume_up_rounded),
                  style: IconButton.styleFrom(backgroundColor: accentColor),
                  onPressed: () => ref
                      .read(playbackControllerProvider)
                      .playSingle(
                        id: glyphBlock.audioUrl!,
                        contentKind: item.kind.name,
                        contentId: item.id,
                        trackType: 'targetNormal',
                        languageCode: 'sat',
                      ),
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
                    color: isDark
                        ? Colors.white70
                        : AppColors.darkSurfaceElevated,
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
              onTracingCompleted();
            }
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _getCalloutColor(CalloutVariant variant) {
    switch (variant) {
      case CalloutVariant.tip:
        return AppColors.primary; // Green
      case CalloutVariant.warning:
        return AppColors.error; // Red
      case CalloutVariant.note:
        return AppColors.brandBlue; // Blue
      case CalloutVariant.success:
        return AppColors.warning; // Amber
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

// Bottom action footer: typing-practice launcher (with the audio
// controls bar) or the lesson-completion CTA gated on tracing.
class _ContentDetailFooter extends ConsumerWidget {
  const _ContentDetailFooter({
    required this.item,
    required this.accentColor,
    required this.isDark,
    required this.isTracingCompleted,
    required this.onCompleteContent,
  });

  final ContentItem item;
  final Color accentColor;
  final bool isDark;
  final bool isTracingCompleted;
  final Future<void> Function(ContentItem item) onCompleteContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // Mode-aware audio bundle (targetOnly/bilingual/translationOnDemand):
        // Phase 2 audio_tracks + localized_contents with legacy inline
        // fields as offline-first fallback. Failure-swallowing by design.
        final bundleAsync = ref.watch(
          audioBundleProvider(
            AudioBundleRequest(
              contentKind: item.kind.name,
              contentId: item.id,
              legacyAudioUrl: item.effectiveAudioUrl,
              legacyMeaning: item.subtitle ?? '',
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.quizDarkCardAlt : Colors.white)
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full pedagogical controls (Santali/Slow/Meaning/Repeat/
                // speed/progress) routed through the central controller.
                // The bundle itself surfaces unavailable states, so the
                // bar renders whenever the bundle resolved.
                bundleAsync.maybeWhen(
                  data: (bundle) => AudioControlsBar(bundle: bundle),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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
        color: (isDark ? AppColors.quizDarkCardAlt : Colors.white).withOpacity(
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
            onPressed: isTracingCompleted
                ? () => unawaited(onCompleteContent(item))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              disabledBackgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              isTracingCompleted
                  ? Icons.check_circle_outline
                  : Icons.gesture_rounded,
            ),
            label: Text(
              isTracingCompleted
                  ? 'Finish Practice (+25 stars)'
                  : 'Complete Tracing Exercise first',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
