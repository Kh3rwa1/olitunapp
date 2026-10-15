import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/theme/app_typography.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../rhymes/presentation/providers/rhyme_audio_provider.dart';
import '../../../../rhymes/presentation/widgets/cover_hero.dart';
import '../../../../rhymes/presentation/widgets/enchanted_visualizer.dart';

/// Playback speeds the speed chip cycles through.
const premiumBakhedSpeedCycle = <double>[1.0, 1.25, 1.5, 0.75];

/// `mm:ss` for the scrubber labels.
String formatBakhedDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Back button, BAKHED badge, title and subtitle.
class PremiumBakhedTopBar extends StatelessWidget {
  const PremiumBakhedTopBar({
    super.key,
    required this.item,
    required this.accentColor,
    this.isCompact = false,
  });

  final ContentItem item;
  final Color accentColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              tooltip: 'Go back',
              onPressed: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.bakhedLabel,
                      style: AppTypography.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: isCompact ? 17 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 16:9 cover artwork with the playback visualizer along the bottom edge.
class PremiumBakhedArtworkCard extends StatelessWidget {
  const PremiumBakhedArtworkCard({
    super.key,
    required this.item,
    required this.accentColor,
    required this.isPlaying,
    required this.maxHeight,
  });

  final ContentItem item;
  final Color accentColor;
  final bool isPlaying;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: maxHeight * (16 / 9),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverHero(
                  media: item.heroMedia,
                  coverMediaType: item.coverMediaType,
                  fallback: Container(
                    color: AppColors.bakhedCardDark,
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 48,
                      color: accentColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TickerMode(
                    enabled: isPlaying,
                    child: EnchantedVisualizer(
                      isPlaying: isPlaying,
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 56,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seek slider with position / duration labels.
class PremiumBakhedSliderSection extends ConsumerWidget {
  const PremiumBakhedSliderSection({
    super.key,
    required this.accentColor,
    required this.maxSliderVal,
    required this.currentSliderVal,
    required this.hasValidDuration,
    required this.positionMs,
    required this.durationMs,
    required this.isPlaying,
  });

  final Color accentColor;
  final double maxSliderVal;
  final double currentSliderVal;
  final bool hasValidDuration;
  final int positionMs;
  final int durationMs;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            trackHeight: 3.5,
            overlayColor: accentColor.withValues(alpha: 0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: MouseRegion(
            cursor: hasValidDuration
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Slider(
              max: maxSliderVal,
              value: currentSliderVal,
              onChanged: hasValidDuration
                  ? (val) {
                      ref
                          .read(rhymeAudioProvider.notifier)
                          .seek(Duration(milliseconds: val.toInt()));
                    }
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatBakhedDuration(Duration(milliseconds: positionMs)),
                style: AppTypography.inter(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hasValidDuration
                    ? formatBakhedDuration(Duration(milliseconds: durationMs))
                    : (isPlaying ? '--:--' : '00:00'),
                style: AppTypography.inter(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Speed chip, ±10s skip and the play/pause button.
class PremiumBakhedControlsRow extends ConsumerWidget {
  const PremiumBakhedControlsRow({
    super.key,
    required this.item,
    required this.accentColor,
    required this.isPlaying,
    required this.positionMs,
    required this.durationMs,
    required this.speed,
    this.isCompact = false,
  });

  final ContentItem item;
  final Color accentColor;
  final bool isPlaying;
  final int positionMs;
  final int durationMs;
  final double speed;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Speed button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: 'Playback speed',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                const cycle = premiumBakhedSpeedCycle;
                final nextSpeed =
                    cycle[(cycle.indexOf(speed) + 1) % cycle.length];
                ref.read(rhymeAudioProvider.notifier).setSpeed(nextSpeed);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  '${speed}x',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Replay 10s
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(
              Icons.replay_10_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: isCompact ? 26 : 28,
            ),
            tooltip: 'Rewind 10 seconds',
            onPressed: () {
              HapticFeedback.lightImpact();
              final pos = Duration(milliseconds: positionMs);
              final target = pos - const Duration(seconds: 10);
              ref
                  .read(rhymeAudioProvider.notifier)
                  .seek(target < Duration.zero ? Duration.zero : target);
            },
          ),
        ),
        const SizedBox(width: 12),

        // Grand Play/Pause Circle
        Semantics(
          button: true,
          label: isPlaying ? 'Pause audio' : 'Play audio',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
                width: isCompact ? 56 : 64,
                height: isCompact ? 56 : 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.38),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: isCompact ? 32 : 36,
                  color: AppColors.bakhedControlDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Forward 10s
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(
              Icons.forward_10_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: isCompact ? 26 : 28,
            ),
            tooltip: 'Forward 10 seconds',
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
        ),
        const SizedBox(width: 14),

        // Symmetrical placeholder for speed button
        const SizedBox(width: 36),
      ],
    );
  }
}
