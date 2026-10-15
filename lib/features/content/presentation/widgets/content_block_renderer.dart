import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/media/olitun_image_cache.dart';
import 'package:itun/core/presentation/animations/scale_button.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/widgets/lottie_display.dart';
import 'package:itun/shared/widgets/tracing_canvas.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/audio_playback_providers.dart';
import 'inline_media_players.dart';

// Renders a single ContentBlock (text/image/video/audio/lottie/quiz/
// glyph/callout/tracing) inside the content detail scroll view.
class ContentBlockRenderer extends ConsumerWidget {
  const ContentBlockRenderer({
    super.key,
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
                cacheManager: olitunImageCacheManager,
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
                  color: accentColor.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.takeAQuiz,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.testYourKnowledge,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
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
            color: infoColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: infoColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
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
