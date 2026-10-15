import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/providers/bakhed_content_provider.dart';
import '../../../rhymes/presentation/providers/rhyme_audio_provider.dart';
import 'premium_bakhed/premium_bakhed_layouts.dart';
import 'premium_bakhed/premium_bakhed_view_data.dart';

/// Premium Bakhed immersive player & learning hub (lyrics / vocabulary /
/// cultural notes). Owns its sub-tab selection state.
class PremiumBakhedBody extends ConsumerStatefulWidget {
  final ContentItem item;
  final Color accentColor;
  const PremiumBakhedBody({
    super.key,
    required this.item,
    required this.accentColor,
  });

  @override
  ConsumerState<PremiumBakhedBody> createState() => _PremiumBakhedBodyState();
}

class _PremiumBakhedBodyState extends ConsumerState<PremiumBakhedBody> {
  int _activeSubTab = 0; // 0 = Lyrics, 1 = Vocab, 2 = Cultural Notes
  final _lyricScroll = PremiumBakhedLyricScroll();

  @override
  void dispose() {
    _lyricScroll.dispose();
    super.dispose();
  }

  void _onSelectSubTab(int index) {
    setState(() {
      _activeSubTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildPremiumBakhedBody(
      context,
      widget.item,
      isDark,
      widget.accentColor,
    );
  }

  Widget _buildPremiumBakhedBody(
    BuildContext context,
    ContentItem item,
    bool isDark,
    Color accentColor,
  ) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isPlaying =
        audioState.playingRhymeId == item.id && audioState.isPlaying;

    // Fetch synced learning content
    final learningContentAsync = ref.watch(
      bakhedLearningContentProvider(item.id),
    );

    int durationMs = audioState.duration.inMilliseconds;
    final positionMs = audioState.position.inMilliseconds;

    // Smart fallback: If player stream hasn't resolved total duration yet,
    // infer total length from synced lyrics end timestamp
    if (durationMs <= 0 && learningContentAsync.hasValue) {
      final lyrics = learningContentAsync.value?.lyrics ?? [];
      if (lyrics.isNotEmpty) {
        final lastEndMs = lyrics.map((l) => l.endMs).fold<int>(0, math.max);
        if (lastEndMs > 0) {
          durationMs = lastEndMs;
        }
      }
    }

    final bool hasValidDuration = durationMs > 0;
    final double maxSliderVal = hasValidDuration
        ? durationMs.toDouble()
        : math.max(positionMs.toDouble(), 1.0);
    final double currentSliderVal =
        (hasValidDuration
                ? positionMs.toDouble()
                : (positionMs > 0 ? positionMs.toDouble() : 0.0))
            .clamp(0.0, maxSliderVal);

    final content = learningContentAsync.valueOrNull;
    final hasLyrics =
        (content?.lyrics.isNotEmpty ?? false) ||
        item.blocks.whereType<TextBlock>().any(
          (b) =>
              (b.textOlChiki != null && b.textOlChiki!.isNotEmpty) ||
              (b.textLatin != null && b.textLatin!.isNotEmpty) ||
              b.markdown.isNotEmpty,
        );
    final hasVocab = content?.vocabulary.isNotEmpty ?? false;
    final hasNotes = content?.culturalNotes.isNotEmpty ?? false;
    final hasAnyContent = hasLyrics || hasVocab || hasNotes;

    return Scaffold(
      backgroundColor:
          AppColors.bakhedBackground, // Deep premium midnight black
      body: Stack(
        children: [
          // Ambient blurred accent background glows
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bakhedGlowBlue.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 840;

                final playback = PremiumBakhedPlaybackView(
                  item: item,
                  accentColor: accentColor,
                  speed: audioState.speed,
                  isPlaying: isPlaying,
                  durationMs: durationMs,
                  positionMs: positionMs,
                  hasValidDuration: hasValidDuration,
                  maxSliderVal: maxSliderVal,
                  currentSliderVal: currentSliderVal,
                );

                if (!hasAnyContent) {
                  return isDesktop
                      ? PremiumBakhedFullScreenDesktopLayout(playback: playback)
                      : PremiumBakhedFullScreenMobileLayout(
                          playback: playback,
                          constraints: constraints,
                        );
                }

                final learning = PremiumBakhedLearningView(
                  learningContentAsync: learningContentAsync,
                  hasLyrics: hasLyrics,
                  hasVocab: hasVocab,
                  hasNotes: hasNotes,
                  activeSubTab: _activeSubTab,
                  onSelectSubTab: _onSelectSubTab,
                  lyricScroll: _lyricScroll,
                );

                return isDesktop
                    ? PremiumBakhedDesktopLayout(
                        playback: playback,
                        learning: learning,
                      )
                    : PremiumBakhedMobileLayout(
                        playback: playback,
                        learning: learning,
                        constraints: constraints,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
