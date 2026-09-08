// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';
import 'package:itun/core/theme/app_typography.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../../core/api/appwrite_db_service.dart';
import '../providers/audio_playback_providers.dart';
import '../../../rhymes/presentation/widgets/cover_hero.dart';
import '../../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../../../rhymes/presentation/providers/rhyme_audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/content_item.dart';
import '../../../../shared/providers/bakhed_content_provider.dart';
part 'premium_bakhed_body_content.dart';

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
  static const _speedCycle = <double>[1.0, 1.25, 1.5, 0.75];

  int _activeSubTab = 0; // 0 = Lyrics, 1 = Vocab, 2 = Cultural Notes
  late final ScrollController _lyricScrollController;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _lyricScrollController = ScrollController();
  }

  @override
  void dispose() {
    _lyricScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  Widget _buildActiveSubTabContent(
    BakhedLearningContent content,
    ContentItem item,
    bool isPlaying,
    int positionMs,
    Color accentColor,
  ) {
    switch (_activeSubTab) {
      case 0:
        return _buildSyncedLyrics(
          content.lyrics,
          item,
          positionMs,
          accentColor,
        );
      case 1:
        return _buildVocabularyList(content.vocabulary, accentColor);
      case 2:
        return _buildCulturalNotes(content.culturalNotes);
      default:
        return const SizedBox.shrink();
    }
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
          setState(() {
            _activeSubTab = index;
          });
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
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
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
                    color: const Color(0xFF131A26),
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
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 5.5,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 14,
            ),
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
                final nextSpeed = _speedCycle[
                  (_speedCycle.indexOf(speed) + 1) % _speedCycle.length
                ];
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
                ref.read(rhymeAudioProvider.notifier).togglePlay(
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
                  color: const Color(0xFF0A0E15),
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

  Widget _buildContentSurface(
    AsyncValue<BakhedLearningContent?> learningContentAsync,
    ContentItem item,
    bool isPlaying,
    int positionMs,
    Color accentColor,
  ) {
    return learningContentAsync.when(
      data: (content) {
        if (content == null) {
          return Center(
            child: Text(
              'No learning content available.',
              style: AppTypography.inter(color: Colors.white38, fontSize: 14),
            ),
          );
        }
        return _buildActiveSubTabContent(
          content,
          item,
          isPlaying,
          positionMs,
          accentColor,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading details: $err',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout({
    required BuildContext context,
    required ContentItem item,
    required Color accentColor,
    required RhymeAudioState audioState,
    required AsyncValue<BakhedLearningContent?> learningContentAsync,
    required bool isPlaying,
    required int durationMs,
    required int positionMs,
    required bool hasValidDuration,
    required double maxSliderVal,
    required double currentSliderVal,
  }) {
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
                // Top Bar
                _buildTopBar(context, item, accentColor),
                const SizedBox(height: 18),

                // Artwork Card
                Center(
                  child: _buildArtworkCard(
                    item,
                    accentColor,
                    isPlaying,
                    maxHeight: 240,
                  ),
                ),
                const Spacer(),

                // Scrubber
                _buildSliderSection(
                  accentColor,
                  maxSliderVal,
                  currentSliderVal,
                  hasValidDuration,
                  positionMs,
                  durationMs,
                  isPlaying,
                ),
                const SizedBox(height: 14),

                // Playback Controls Row
                _buildControlsRow(
                  item,
                  accentColor,
                  isPlaying,
                  positionMs,
                  durationMs,
                  audioState.speed,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),

        // Vertical divider line
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.06),
        ),

        // Right Column: Learning Surface
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSubTabsBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildContentSurface(
                      learningContentAsync,
                      item,
                      isPlaying,
                      positionMs,
                      accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required BuildContext context,
    required ContentItem item,
    required Color accentColor,
    required RhymeAudioState audioState,
    required AsyncValue<BakhedLearningContent?> learningContentAsync,
    required bool isPlaying,
    required int durationMs,
    required int positionMs,
    required bool hasValidDuration,
    required double maxSliderVal,
    required double currentSliderVal,
    required BoxConstraints constraints,
  }) {
    final double artMaxHeight =
        (constraints.maxHeight * 0.24).clamp(150.0, 200.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildTopBar(context, item, accentColor, isCompact: true),
        ),

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

        const SizedBox(height: 8),

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

        const SizedBox(height: 10),

        // SubTabs Switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSubTabsBar(isCompact: true),
        ),

        const SizedBox(height: 10),

        // Expanded Scrolling Content Surface
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContentSurface(
              learningContentAsync,
              item,
              isPlaying,
              positionMs,
              accentColor,
            ),
          ),
        ),
      ],
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

    return Scaffold(
      backgroundColor: const Color(0xFF070B13), // Deep premium midnight black
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
                color: accentColor.withOpacity(0.14),
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
                color: const Color(0xFF1E3A8A).withOpacity(0.10),
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
                if (constraints.maxWidth >= 840) {
                  return _buildDesktopLayout(
                    context: context,
                    item: item,
                    accentColor: accentColor,
                    audioState: audioState,
                    learningContentAsync: learningContentAsync,
                    isPlaying: isPlaying,
                    durationMs: durationMs,
                    positionMs: positionMs,
                    hasValidDuration: hasValidDuration,
                    maxSliderVal: maxSliderVal,
                    currentSliderVal: currentSliderVal,
                  );
                } else {
                  return _buildMobileLayout(
                    context: context,
                    item: item,
                    accentColor: accentColor,
                    audioState: audioState,
                    learningContentAsync: learningContentAsync,
                    isPlaying: isPlaying,
                    durationMs: durationMs,
                    positionMs: positionMs,
                    hasValidDuration: hasValidDuration,
                    maxSliderVal: maxSliderVal,
                    currentSliderVal: currentSliderVal,
                    constraints: constraints,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
