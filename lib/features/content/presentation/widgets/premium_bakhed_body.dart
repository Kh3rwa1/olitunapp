import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/app_typography.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../../core/api/appwrite_db_service.dart';
import '../../../../shared/models/content_item.dart';
import '../../../../shared/providers/bakhed_content_provider.dart';
import '../../../rhymes/presentation/providers/rhyme_audio_provider.dart';
import '../../../rhymes/presentation/widgets/cover_hero.dart';
import '../../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../providers/audio_playback_providers.dart';

part 'premium_bakhed_body_content.dart';
part 'premium_bakhed_body_layouts.dart';

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
    required bool hasLyrics,
    required bool hasVocab,
    required bool hasNotes,
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
        Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),

        // Right Column: Learning Surface
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSubTabsBar(
                  hasLyrics: hasLyrics,
                  hasVocab: hasVocab,
                  hasNotes: hasNotes,
                ),
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
                    child: _buildContentSurface(
                      learningContentAsync,
                      item,
                      isPlaying,
                      positionMs,
                      accentColor,
                      hasLyrics: hasLyrics,
                      hasVocab: hasVocab,
                      hasNotes: hasNotes,
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
    required bool hasLyrics,
    required bool hasVocab,
    required bool hasNotes,
  }) {
    final double artMaxHeight = (constraints.maxHeight * 0.24).clamp(
      150.0,
      200.0,
    );

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
          child: _buildSubTabsBar(
            hasLyrics: hasLyrics,
            hasVocab: hasVocab,
            hasNotes: hasNotes,
            isCompact: true,
          ),
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
            child: _buildContentSurface(
              learningContentAsync,
              item,
              isPlaying,
              positionMs,
              accentColor,
              hasLyrics: hasLyrics,
              hasVocab: hasVocab,
              hasNotes: hasNotes,
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

                if (!hasAnyContent) {
                  return isDesktop
                      ? _buildFullScreenDesktopLayout(
                          context: context,
                          item: item,
                          accentColor: accentColor,
                          audioState: audioState,
                          isPlaying: isPlaying,
                          durationMs: durationMs,
                          positionMs: positionMs,
                          hasValidDuration: hasValidDuration,
                          maxSliderVal: maxSliderVal,
                          currentSliderVal: currentSliderVal,
                        )
                      : _buildFullScreenMobileLayout(
                          context: context,
                          item: item,
                          accentColor: accentColor,
                          audioState: audioState,
                          isPlaying: isPlaying,
                          durationMs: durationMs,
                          positionMs: positionMs,
                          hasValidDuration: hasValidDuration,
                          maxSliderVal: maxSliderVal,
                          currentSliderVal: currentSliderVal,
                          constraints: constraints,
                        );
                }

                if (isDesktop) {
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
                    hasLyrics: hasLyrics,
                    hasVocab: hasVocab,
                    hasNotes: hasNotes,
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
                    hasLyrics: hasLyrics,
                    hasVocab: hasVocab,
                    hasNotes: hasNotes,
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
