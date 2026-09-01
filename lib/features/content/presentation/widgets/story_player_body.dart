import 'dart:async';
import 'package:itun/core/theme/app_typography.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/audio/playback_controller.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/entities/audio_track_entity.dart';
import '../../domain/entities/story_segment_entity.dart';
import '../providers/audio_download_providers.dart';
import '../providers/audio_playback_providers.dart';
import '../providers/story_segment_providers.dart';
import 'premium_bakhed_body.dart';

/// Segment-based story player (spec §13 "Segment-based stories" +
/// "Highlighting" + "Bilingual mode" + "Offline download").
///
/// Shown for rhyme-kind bakhed items that have `story_segments` rows.
/// When the item has no segments — or the multilingual-audio flag is
/// off — the screen falls back to the current [PremiumBakhedBody]
/// experience, so nothing regresses (spec §27: keep the existing
/// experience working).
///
/// The player never crashes on missing audio (spec §7): a segment
/// without a narration track renders text-only, and a missing
/// translation simply falls back per [StorySegment.translationFor].
class StoryPlayerBody extends ConsumerStatefulWidget {
  final ContentItem item;
  final Color accentColor;

  const StoryPlayerBody({
    super.key,
    required this.item,
    required this.accentColor,
  });

  @override
  ConsumerState<StoryPlayerBody> createState() => _StoryPlayerBodyState();
}

class _StoryPlayerBodyState extends ConsumerState<StoryPlayerBody> {
  static const _speedCycle = <double>[1.0, 0.75, 0.5, 1.25, 1.5];

  /// Resume-position persistence key (spec §13 "Resume position").
  static String _resumeKey(String storyId) => 'story_resume:$storyId';

  int _currentIndex = 0;
  bool _showTranslation = false;
  bool _bilingualEmitted = false;
  bool _storyStartedEmitted = false;
  double _speed = 1.0;
  late final ScrollController _segmentScroll;

  /// Guards the auto-advance listener so a manual pause does not skip
  /// the learner to the next segment — only a natural chain finish
  /// (isPlaying → false without a pause request) advances.
  bool _awaitingNaturalEnd = false;

  @override
  void initState() {
    super.initState();
    _segmentScroll = ScrollController();
    // Deferred so ref is usable inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(playbackControllerProvider).addListener(_onPlaybackState);
      _restoreResumePosition();
    });
  }

  @override
  void dispose() {
    _saveResumePosition();
    try {
      ref.read(playbackControllerProvider).removeListener(_onPlaybackState);
    } catch (_) {
      // Provider already disposed — nothing to detach.
    }
    _segmentScroll.dispose();
    super.dispose();
  }

  Future<void> _restoreResumePosition() async {
    try {
      // CacheService only round-trips map payloads, so the index is
      // wrapped: {'segmentIndex': <int>}.
      final saved = await CacheService.get<Map<String, dynamic>>(
        _resumeKey(widget.item.id),
        (json) => json,
      );
      final index = saved?['segmentIndex'];
      if (index is int && index > 0 && mounted) {
        setState(() => _currentIndex = index);
        _scrollToSegment(index);
      }
    } catch (e) {
      AppLogger.warning('StoryPlayerBody: resume restore failed: $e');
    }
  }

  Future<void> _saveResumePosition() async {
    try {
      await CacheService.set(_resumeKey(widget.item.id), <String, dynamic>{
        'segmentIndex': _currentIndex,
      }, ttl: const Duration(days: 30));
    } catch (_) {
      // Resume persistence is best-effort; never block the reader.
    }
  }

  /// Advances to the next segment when the current segment's audio
  /// chain finishes *naturally* (not via a manual pause).
  void _onPlaybackState(PlaybackState state) {
    if (!mounted) return;
    if (_awaitingNaturalEnd &&
        !state.isPlaying &&
        !state.isLoading &&
        state.error == null &&
        state.current?.contentId == widget.item.id) {
      _awaitingNaturalEnd = false;
      _goToSegment(_currentIndex + 1, autoplay: true);
    }
  }

  // ── Audio plumbing ────────────────────────────────────────────────

  /// Best URL for a track: the downloaded local `file://` file when
  /// present, else the remote URL. Returns null when neither exists.
  Future<String?> _resolveUrl(AudioTrack track) async {
    final remote = track.audioUrl;
    if (remote == null || remote.isEmpty) return null;
    if (!ref.read(downloadsAvailableProvider)) return remote;
    try {
      final manager = ref.read(audioDownloadManagerProvider);
      final local = await manager.localFileUrlFor(track);
      if (local != null) return local;
    } catch (_) {
      // Downloads are best-effort; remote streaming is the fallback.
    }
    return remote;
  }

  /// Plays segment [index]: Santali narration, followed by the
  /// teaching-language translation when bilingual mode is on (spec
  /// §13 "Bilingual playback mode"). No narration → text-only, no
  /// crash.
  Future<void> _playSegment(int index, {required bool auto}) async {
    final segments = ref
        .read(storySegmentsProvider(widget.item.id))
        .valueOrNull;
    if (segments == null || segments.isEmpty) return;
    final clamped = index.clamp(0, segments.length - 1);

    final analytics = ref.read(learningAnalyticsServiceProvider);
    final teachingLanguage = ref.read(effectiveTeachingLanguageProvider);
    final audioMode = ref.read(lessonAudioModeProvider);
    final bilingualFlag = ref
        .read(featureFlagsProvider)
        .bilingualPlaybackEnabled;

    final segment = segments[clamped];
    final narration = segment.narrationTrack;
    if (mounted) {
      setState(() => _currentIndex = clamped);
      _scrollToSegment(clamped);
    }
    _saveResumePosition();

    if (narration == null) {
      // Text-only segment (spec §7: never block on missing audio).
      await analytics.track(
        LearningAnalyticsEvents.storySegmentPlayed,
        source: 'story',
        sourceId: widget.item.id,
        metadata: {
          'contentKind': 'story',
          'segmentIndex': clamped,
          'hasNarration': false,
          'autoAdvance': auto,
        },
      );
      return;
    }

    final narrationUrl = await _resolveUrl(narration);
    if (narrationUrl == null) return;

    final requests = <PlaybackRequest>[
      PlaybackRequest(
        id: narrationUrl,
        contentKind: 'story',
        contentId: widget.item.id,
        trackType: 'storyNarration',
        languageCode: 'sat',
      ),
    ];

    if (audioMode == LessonAudioMode.bilingual && bilingualFlag) {
      final translation = segment.translationTrackFor(teachingLanguage);
      if (translation != null) {
        final translationUrl = await _resolveUrl(translation);
        if (translationUrl != null) {
          requests.add(
            PlaybackRequest(
              id: translationUrl,
              contentKind: 'story',
              contentId: widget.item.id,
              trackType: 'storyTranslation',
              languageCode: teachingLanguage,
            ),
          );
        }
      }
      if (!_bilingualEmitted) {
        _bilingualEmitted = true;
        await analytics.track(
          LearningAnalyticsEvents.bilingualModeEnabled,
          source: 'story',
          sourceId: widget.item.id,
          metadata: {
            'selectedTeachingLanguage': teachingLanguage,
            'playbackMode': audioMode.name,
          },
        );
      }
    }

    _awaitingNaturalEnd = true;
    await ref
        .read(playbackControllerProvider)
        .play(PlaybackRequest.chain(requests)!);
    if (_speed != 1.0) {
      await ref.read(playbackControllerProvider).setSpeed(_speed);
    }

    await analytics.track(
      LearningAnalyticsEvents.storySegmentPlayed,
      source: 'story',
      sourceId: widget.item.id,
      metadata: {
        'contentKind': 'story',
        'contentId': widget.item.id,
        'segmentIndex': clamped,
        'trackType': 'storyNarration',
        'playbackMode': audioMode.name,
        'playbackSpeed': _speed,
        'offline': narrationUrl.startsWith('file://'),
        'hasNarration': true,
      },
    );
  }

  /// Plays the teaching-language translation on demand (spec §13
  /// "Translation audio on demand").
  Future<void> _playTranslationAudio() async {
    final segments = ref
        .read(storySegmentsProvider(widget.item.id))
        .valueOrNull;
    if (segments == null || segments.isEmpty) return;
    final teachingLanguage = ref.read(effectiveTeachingLanguageProvider);
    final segment = segments[_currentIndex.clamp(0, segments.length - 1)];
    final track = segment.translationTrackFor(teachingLanguage);
    if (track == null) return;
    final url = await _resolveUrl(track);
    if (url == null) return;
    _awaitingNaturalEnd = false;
    await ref
        .read(playbackControllerProvider)
        .playSingle(
          id: url,
          contentKind: 'story',
          contentId: widget.item.id,
          trackType: 'storyTranslation',
          languageCode: teachingLanguage,
        );
    await ref
        .read(learningAnalyticsServiceProvider)
        .track(
          LearningAnalyticsEvents.translationAudioPlayed,
          source: 'story',
          sourceId: widget.item.id,
          metadata: {
            'contentKind': 'story',
            'segmentIndex': _currentIndex,
            'trackType': 'storyTranslation',
            'languageCode': teachingLanguage,
          },
        );
  }

  void _goToSegment(int index, {required bool autoplay}) {
    if (autoplay) {
      _playSegment(index, auto: true);
    } else if (mounted) {
      setState(() => _currentIndex = index);
      _scrollToSegment(index);
      _saveResumePosition();
    }
  }

  void _scrollToSegment(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_segmentScroll.hasClients) return;
      final target = (index * 190.0).clamp(
        0.0,
        _segmentScroll.position.maxScrollExtent,
      );
      _segmentScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _cycleSpeed() {
    final next =
        _speedCycle[(_speedCycle.indexOf(_speed) + 1) % _speedCycle.length];
    setState(() => _speed = next);
    ref.read(playbackControllerProvider).setSpeed(next);
  }

  void _togglePlayPause(PlaybackState playback) {
    final controller = ref.read(playbackControllerProvider);
    final isActiveStory =
        playback.current?.contentId == widget.item.id && !playback.isIdle;
    if (isActiveStory && (playback.isPlaying || playback.isLoading)) {
      _awaitingNaturalEnd = false;
      controller.pause();
    } else if (isActiveStory && playback.current != null) {
      controller.resume();
      _awaitingNaturalEnd = true;
    } else {
      _playSegment(_currentIndex, auto: false);
    }
  }

  void _toggleTranslation(List<StorySegment> segments) {
    final teachingLanguage = ref.read(effectiveTeachingLanguageProvider);
    final segment = segments[_currentIndex.clamp(0, segments.length - 1)];
    final missingRequested = segment.translations[teachingLanguage] == null;
    setState(() => _showTranslation = !_showTranslation);
    if (_showTranslation && missingRequested) {
      // Fallback text is being shown for the requested language
      // (spec §16: translation_fallback_used).
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.translationFallbackUsed,
            source: 'story',
            sourceId: widget.item.id,
            metadata: {
              'requestedLanguage': teachingLanguage,
              'segmentIndex': _currentIndex,
            },
          );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    // Flag off → current experience, untouched (spec §27).
    if (!flags.multilingualAudioEnabled) {
      return PremiumBakhedBody(
        item: widget.item,
        accentColor: widget.accentColor,
      );
    }

    final segmentsAsync = ref.watch(storySegmentsProvider(widget.item.id));

    return segmentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) =>
          PremiumBakhedBody(item: widget.item, accentColor: widget.accentColor),
      data: (segments) {
        if (segments.isEmpty) {
          return PremiumBakhedBody(
            item: widget.item,
            accentColor: widget.accentColor,
          );
        }
        _emitStoryStarted(segments.length);
        return _buildPlayer(segments);
      },
    );
  }

  void _emitStoryStarted(int segmentCount) {
    if (_storyStartedEmitted) return;
    _storyStartedEmitted = true;
    ref
        .read(learningAnalyticsServiceProvider)
        .track(
          LearningAnalyticsEvents.storyStarted,
          source: 'story',
          sourceId: widget.item.id,
          metadata: {
            'contentKind': 'story',
            'contentId': widget.item.id,
            'segmentCount': segmentCount,
            'selectedTeachingLanguage': ref.read(
              effectiveTeachingLanguageProvider,
            ),
          },
        );
  }

  Widget _buildPlayer(List<StorySegment> segments) {
    final playback = ref.watch(playbackControllerProvider).state;
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final teachingLanguage = ref.watch(effectiveTeachingLanguageProvider);
    final downloadAvailable = ref.watch(downloadsAvailableProvider);
    final downloadState = ref.watch(storyDownloadStateProvider(widget.item.id));

    final currentSegment =
        segments[_currentIndex.clamp(0, segments.length - 1)];
    final isActiveStory = playback.current?.contentId == widget.item.id;
    final isSegmentPlaying =
        isActiveStory && (playback.isPlaying || playback.isLoading);

    return Container(
      color: const Color(0xFF070B13),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _segmentScroll,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              itemCount: segments.length,
              itemBuilder: (context, index) {
                final segment = segments[index];
                final isActive = index == _currentIndex;
                return _buildSegmentCard(
                  segment: segment,
                  index: index,
                  isActive: isActive,
                  isPlaying: isActive && isSegmentPlaying,
                  scriptMode: scriptMode,
                  teachingLanguage: teachingLanguage,
                  onTap: () {
                    _currentIndex = index;
                    _playSegment(index, auto: false);
                  },
                );
              },
            ),
          ),
          _buildControlsBar(
            segments: segments,
            currentSegment: currentSegment,
            playback: playback,
            isSegmentPlaying: isSegmentPlaying,
            downloadAvailable: downloadAvailable,
            downloadState: downloadState,
            teachingLanguage: teachingLanguage,
          ),
        ],
      ),
    );
  }

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
