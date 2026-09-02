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
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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

  Widget _buildSubTabButton(int index, IconData icon, String label) {
    final isSelected = _activeSubTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _activeSubTab = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.12))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
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
          // Ambient blurred accent background
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.12),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom glassy top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Container(
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
                            size: 20,
                          ),
                          tooltip: 'Go back',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.maybePop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (item.subtitle != null &&
                                item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cover Art & Visualizer Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.18),
                            blurRadius: 36,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Thumbnail / Cover Art Image / Video Autoplay
                            CoverHero(
                              media: item.heroMedia,
                              coverMediaType: item.coverMediaType,
                              fallback: Container(
                                color: const Color(0xFF151C2A),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 64,
                                  color: accentColor,
                                ),
                              ),
                            ),

                            // Visualizer Overlay
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: TickerMode(
                                enabled: isPlaying,
                                child: EnchantedVisualizer(
                                  isPlaying: isPlaying,
                                  color: Colors.white.withOpacity(0.25),
                                  height: 80,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Audio Progress Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.12),
                      thumbColor: Colors.white,
                      trackHeight: 4,
                      overlayColor: accentColor.withOpacity(0.16),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
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

                // Timestamps Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(milliseconds: positionMs)),
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        hasValidDuration
                            ? _formatDuration(
                                Duration(milliseconds: durationMs),
                              )
                            : (isPlaying ? '--:--' : '00:00'),
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Audio Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Replay 10s
                      IconButton(
                        icon: Icon(
                          Icons.replay_10_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
                        ),
                        tooltip: 'Rewind 10 seconds',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final pos = Duration(milliseconds: positionMs);
                          final target = pos - const Duration(seconds: 10);
                          ref
                              .read(rhymeAudioProvider.notifier)
                              .seek(
                                target < Duration.zero ? Duration.zero : target,
                              );
                        },
                      ),
                      const SizedBox(width: 24),
                      // Grand Play/Pause Circle
                      Semantics(
                        button: true,
                        label: isPlaying ? 'Pause audio' : 'Play audio',
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
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.35),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              color: const Color(0xFF0A0E15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Forward 10s
                      IconButton(
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
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
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Glassy Learning Sub-Tabs Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSubTabButton(
                            0,
                            Icons.lyrics_rounded,
                            'Lyrics',
                          ),
                        ),
                        Expanded(
                          child: _buildSubTabButton(
                            1,
                            Icons.menu_book_rounded,
                            'Vocabulary',
                          ),
                        ),
                        Expanded(
                          child: _buildSubTabButton(
                            2,
                            Icons.auto_stories_rounded,
                            'Notes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scrolling Content Panel
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    child: learningContentAsync.when(
                      data: (content) {
                        return _buildActiveSubTabContent(
                          content,
                          item,
                          isPlaying,
                          positionMs,
                          accentColor,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
