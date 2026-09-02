part of 'story_player_body.dart';

// Segment cards, the controls bar and the download button for
// [_StoryPlayerBodyState], extracted into this library part.
extension _StoryPlayerBodyViews on _StoryPlayerBodyState {
  Widget _buildSegmentCard({
    required StorySegment segment,
    required int index,
    required bool isActive,
    required bool isPlaying,
    required String scriptMode,
    required String teachingLanguage,
    required VoidCallback onTap,
  }) {
    final showOl = scriptMode != 'romanized';
    final showLatin = scriptMode != 'olchiki' && segment.textLatin != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: isActive ? AppColors.primary : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPlaying)
                  const Icon(
                    Icons.graphic_eq,
                    color: AppColors.primary,
                    size: 18,
                  ),
                const Spacer(),
                if (segment.narrationTrack == null)
                  const Tooltip(
                    message: 'Text only',
                    child: Icon(
                      Icons.text_snippet_outlined,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (showOl)
              Text(
                segment.textOlChiki,
                style: AppTypography.inter(
                  fontSize: 22,
                  height: 1.5,
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            if (showLatin) ...[
              const SizedBox(height: 6),
              Text(
                segment.textLatin!,
                style: AppTypography.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: isActive ? Colors.white60 : Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_showTranslation) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  segment.translationFor(teachingLanguage),
                  style: AppTypography.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
            if (segment.vocabularyRefs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final wordId in segment.vocabularyRefs)
                    ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide.none,
                      avatar: const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                      label: Text(
                        'word',
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      onPressed: () => context.push('/content/word/$wordId'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar({
    required List<StorySegment> segments,
    required StorySegment currentSegment,
    required PlaybackState playback,
    required bool isSegmentPlaying,
    required bool downloadAvailable,
    required StoryDownloadState downloadState,
    required String teachingLanguage,
  }) {
    final hasTranslationAudio =
        currentSegment.translationTrackFor(teachingLanguage) != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playback.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  playback.error!,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  label: 'Prev',
                  onPressed: _currentIndex > 0
                      ? () => _goToSegment(_currentIndex - 1, autoplay: true)
                      : null,
                ),
                _ControlButton(
                  icon: isSegmentPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: isSegmentPlaying ? 'Pause' : 'Play',
                  onPressed: () => _togglePlayPause(playback),
                  isPrimary: true,
                ),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Next',
                  onPressed: _currentIndex < segments.length - 1
                      ? () => _goToSegment(_currentIndex + 1, autoplay: true)
                      : null,
                ),
                _ControlButton(
                  icon: Icons.speed_rounded,
                  label: '${_speed}x',
                  onPressed: _cycleSpeed,
                ),
                _ControlButton(
                  icon: _showTranslation
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  label: 'Text',
                  onPressed: () => _toggleTranslation(segments),
                ),
                if (hasTranslationAudio)
                  _ControlButton(
                    icon: Icons.translate_rounded,
                    label: 'Audio',
                    onPressed: _playTranslationAudio,
                  ),
                if (downloadAvailable) _buildDownloadButton(downloadState),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(StoryDownloadState downloadState) {
    if (downloadState.status == DownloadStatus.downloading) {
      return SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                value: downloadState.total > 0 ? downloadState.progress : null,
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            GestureDetector(
              onTap: () => ref
                  .read(audioDownloadProvider.notifier)
                  .cancelStoryDownload(widget.item.id),
              child: Text(
                'cancel',
                style: AppTypography.inter(fontSize: 10, color: Colors.white38),
              ),
            ),
          ],
        ),
      );
    }
    final downloaded = downloadState.status == DownloadStatus.downloaded;
    return _ControlButton(
      icon: downloaded ? Icons.download_done_rounded : Icons.download_rounded,
      label: downloaded ? 'Saved' : 'Get',
      onPressed: downloaded
          ? null
          : () async {
              final segments = ref
                  .read(storySegmentsProvider(widget.item.id))
                  .valueOrNull;
              if (segments == null) return;
              await ref
                  .read(audioDownloadProvider.notifier)
                  .downloadStory(
                    widget.item.id,
                    downloadableTracksFromSegments(segments),
                  );
            },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: label,
          icon: Icon(
            icon,
            size: isPrimary ? 34 : 24,
            color: enabled
                ? (isPrimary ? AppColors.primary : Colors.white70)
                : Colors.white24,
          ),
        ),
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 10,
            color: enabled ? Colors.white54 : Colors.white24,
          ),
        ),
      ],
    );
  }
}
