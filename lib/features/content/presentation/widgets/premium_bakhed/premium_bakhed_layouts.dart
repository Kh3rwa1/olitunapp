import 'package:flutter/material.dart';

import 'premium_bakhed_controls.dart';
import 'premium_bakhed_panels.dart';
import 'premium_bakhed_sub_tabs.dart';
import 'premium_bakhed_view_data.dart';

/// Builds the scrubber for [playback].
Widget _slider(PremiumBakhedPlaybackView playback) {
  return PremiumBakhedSliderSection(
    accentColor: playback.accentColor,
    maxSliderVal: playback.maxSliderVal,
    currentSliderVal: playback.currentSliderVal,
    hasValidDuration: playback.hasValidDuration,
    positionMs: playback.positionMs,
    durationMs: playback.durationMs,
    isPlaying: playback.isPlaying,
  );
}

/// Builds the transport controls for [playback].
Widget _controls(PremiumBakhedPlaybackView playback, {bool isCompact = false}) {
  return PremiumBakhedControlsRow(
    item: playback.item,
    accentColor: playback.accentColor,
    isPlaying: playback.isPlaying,
    positionMs: playback.positionMs,
    durationMs: playback.durationMs,
    speed: playback.speed,
    isCompact: isCompact,
  );
}

Widget _artwork(PremiumBakhedPlaybackView playback, double maxHeight) {
  return PremiumBakhedArtworkCard(
    item: playback.item,
    accentColor: playback.accentColor,
    isPlaying: playback.isPlaying,
    maxHeight: maxHeight,
  );
}

Widget _subTabs(PremiumBakhedLearningView learning, {bool isCompact = false}) {
  return PremiumBakhedSubTabsBar(
    activeSubTab: learning.activeSubTab,
    onSelect: learning.onSelectSubTab,
    hasLyrics: learning.hasLyrics,
    hasVocab: learning.hasVocab,
    hasNotes: learning.hasNotes,
    isCompact: isCompact,
  );
}

Widget _surface(
  PremiumBakhedPlaybackView playback,
  PremiumBakhedLearningView learning,
) {
  return PremiumBakhedContentSurface(
    learning: learning,
    item: playback.item,
    positionMs: playback.positionMs,
    accentColor: playback.accentColor,
  );
}

/// Wide layout: player deck on the left, learning surface on the right.
class PremiumBakhedDesktopLayout extends StatelessWidget {
  const PremiumBakhedDesktopLayout({
    super.key,
    required this.playback,
    required this.learning,
  });

  final PremiumBakhedPlaybackView playback;
  final PremiumBakhedLearningView learning;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Player Deck
        SizedBox(
          width: 440,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumBakhedTopBar(
                  item: playback.item,
                  accentColor: playback.accentColor,
                ),
                const SizedBox(height: 18),
                Center(child: _artwork(playback, 240)),
                const Spacer(),
                _slider(playback),
                const SizedBox(height: 14),
                _controls(playback),
                const Spacer(),
              ],
            ),
          ),
        ),

        // Vertical divider line
        Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),

        // Right Column: Learning Surface
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _subTabs(learning),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _surface(playback, learning),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Narrow layout: compact player stacked above the learning surface.
class PremiumBakhedMobileLayout extends StatelessWidget {
  const PremiumBakhedMobileLayout({
    super.key,
    required this.playback,
    required this.learning,
    required this.constraints,
  });

  final PremiumBakhedPlaybackView playback;
  final PremiumBakhedLearningView learning;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final double artMaxHeight = (constraints.maxHeight * 0.24).clamp(
      150.0,
      200.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: PremiumBakhedTopBar(
            item: playback.item,
            accentColor: playback.accentColor,
            isCompact: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(child: _artwork(playback, artMaxHeight)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _slider(playback),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _controls(playback, isCompact: true),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _subTabs(learning, isCompact: true),
        ),
        const SizedBox(height: 10),
        // Expanded Scrolling Content Surface
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _surface(playback, learning),
          ),
        ),
      ],
    );
  }
}

/// Wide player-only layout used when the Bakhed has no learning content.
class PremiumBakhedFullScreenDesktopLayout extends StatelessWidget {
  const PremiumBakhedFullScreenDesktopLayout({
    super.key,
    required this.playback,
  });

  final PremiumBakhedPlaybackView playback;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumBakhedTopBar(
                item: playback.item,
                accentColor: playback.accentColor,
              ),
              const Spacer(),
              Center(child: _artwork(playback, 360)),
              const Spacer(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _slider(playback),
                ),
              ),
              const SizedBox(height: 18),
              _controls(playback),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Narrow player-only layout used when the Bakhed has no learning content.
class PremiumBakhedFullScreenMobileLayout extends StatelessWidget {
  const PremiumBakhedFullScreenMobileLayout({
    super.key,
    required this.playback,
    required this.constraints,
  });

  final PremiumBakhedPlaybackView playback;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final double artMaxHeight = (constraints.maxHeight * 0.44).clamp(
      180.0,
      340.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: PremiumBakhedTopBar(
            item: playback.item,
            accentColor: playback.accentColor,
            isCompact: true,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(child: _artwork(playback, artMaxHeight)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _slider(playback),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _controls(playback, isCompact: true),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
