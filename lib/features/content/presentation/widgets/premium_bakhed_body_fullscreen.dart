part of 'premium_bakhed_body.dart';

extension _PremiumBakhedBodyFullscreen on _PremiumBakhedBodyState {
  Widget _buildFullScreenDesktopLayout({
    required BuildContext context,
    required ContentItem item,
    required Color accentColor,
    required RhymeAudioState audioState,
    required bool isPlaying,
    required int durationMs,
    required int positionMs,
    required bool hasValidDuration,
    required double maxSliderVal,
    required double currentSliderVal,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              _buildTopBar(context, item, accentColor),
              const Spacer(),

              // Artwork Card
              Center(
                child: _buildArtworkCard(
                  item,
                  accentColor,
                  isPlaying,
                  maxHeight: 360,
                ),
              ),
              const Spacer(),

              // Scrubber
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildSliderSection(
                    accentColor,
                    maxSliderVal,
                    currentSliderVal,
                    hasValidDuration,
                    positionMs,
                    durationMs,
                    isPlaying,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Playback Controls Row
              _buildControlsRow(
                item,
                accentColor,
                isPlaying,
                positionMs,
                durationMs,
                audioState.speed,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenMobileLayout({
    required BuildContext context,
    required ContentItem item,
    required Color accentColor,
    required RhymeAudioState audioState,
    required bool isPlaying,
    required int durationMs,
    required int positionMs,
    required bool hasValidDuration,
    required double maxSliderVal,
    required double currentSliderVal,
    required BoxConstraints constraints,
  }) {
    final double artMaxHeight = (constraints.maxHeight * 0.44).clamp(
      180.0,
      340.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildTopBar(context, item, accentColor, isCompact: true),
        ),
        const Spacer(),

        // Artwork Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: _buildArtworkCard(
              item,
              accentColor,
              isPlaying,
              maxHeight: artMaxHeight,
            ),
          ),
        ),
        const Spacer(),

        // Scrubber
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSliderSection(
            accentColor,
            maxSliderVal,
            currentSliderVal,
            hasValidDuration,
            positionMs,
            durationMs,
            isPlaying,
          ),
        ),
        const SizedBox(height: 8),

        // Playback Controls Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildControlsRow(
            item,
            accentColor,
            isPlaying,
            positionMs,
            durationMs,
            audioState.speed,
            isCompact: true,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
