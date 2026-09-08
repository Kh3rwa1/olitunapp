// ignore_for_file: deprecated_member_use
part of 'premium_bakhed_body.dart';

extension _PremiumBakhedBodyLayouts on _PremiumBakhedBodyState {
  Widget _buildTopBar(
    BuildContext context,
    ContentItem item,
    Color accentColor, {
    bool isCompact = false,
  }) {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                Navigator.maybePop(context);
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
                      color: accentColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'BAKHED',
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

  Widget _buildArtworkCard(
    ContentItem item,
    Color accentColor,
    bool isPlaying, {
    required double maxHeight,
  }) {
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
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.22),
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
                      color: Colors.white.withOpacity(0.3),
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

  Widget _buildSliderSection(
    Color accentColor,
    double maxSliderVal,
    double currentSliderVal,
    bool hasValidDuration,
    int positionMs,
    int durationMs,
    bool isPlaying,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white.withOpacity(0.12),
            thumbColor: Colors.white,
            trackHeight: 3.5,
            overlayColor: accentColor.withOpacity(0.18),
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
                _formatDuration(Duration(milliseconds: positionMs)),
                style: AppTypography.inter(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hasValidDuration
                    ? _formatDuration(Duration(milliseconds: durationMs))
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

  Widget _buildControlsRow(
    ContentItem item,
    Color accentColor,
    bool isPlaying,
    int positionMs,
    int durationMs,
    double speed, {
    bool isCompact = false,
  }) {
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
                const cycle = _PremiumBakhedBodyState._speedCycle;
                final nextSpeed =
                    cycle[(cycle.indexOf(speed) + 1) % cycle.length];
                ref.read(rhymeAudioProvider.notifier).setSpeed(nextSpeed);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              color: Colors.white.withOpacity(0.85),
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
                      color: accentColor.withOpacity(0.38),
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
              color: Colors.white.withOpacity(0.85),
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

  Widget _buildSubTabButton(
    int index,
    IconData icon,
    String label, {
    bool isCompact = false,
  }) {
    final isSelected = _activeSubTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _onSelectSubTab(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.12))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isSelected ? AppColors.primary : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabsBar({bool isCompact = false}) {
    return Container(
      height: isCompact ? 46 : 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSubTabButton(
              0,
              Icons.lyrics_rounded,
              'Lyrics',
              isCompact: isCompact,
            ),
          ),
          Expanded(
            child: _buildSubTabButton(
              1,
              Icons.menu_book_rounded,
              'Vocabulary',
              isCompact: isCompact,
            ),
          ),
          Expanded(
            child: _buildSubTabButton(
              2,
              Icons.auto_stories_rounded,
              'Notes',
              isCompact: isCompact,
            ),
          ),
        ],
      ),
    );
  }
}
