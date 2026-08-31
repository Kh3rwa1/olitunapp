// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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

  Widget _buildCulturalNotes(List<BakhedCulturalNote> notes) {
    final publishedNotes = notes.where((n) => n.isPublished).toList();
    if (publishedNotes.isEmpty) {
      return Center(
        child: Text(
          'Cultural notes are being prepared.',
          style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: publishedNotes.length,
      itemBuilder: (context, index) {
        final note = publishedNotes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_added_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: note.body,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              if (note.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),
                Text(
                  'Source: ${note.source}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVocabularyList(
    List<BakhedVocabularyItem> vocabulary,
    Color accentColor,
  ) {
    if (vocabulary.isEmpty) {
      return Center(
        child: Text(
          'No vocabulary items defined.',
          style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: vocabulary.length,
      itemBuilder: (context, index) {
        final item = vocabulary[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.olChiki,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.latin,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (item.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.meaning,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.audioFileId.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: accentColor),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final db = ref.read(appwriteDbServiceProvider);
                      final url = db.getFileViewUrl('audio', item.audioFileId);
                      ref
                          .read(playbackControllerProvider)
                          .playSingle(
                            id: url,
                            contentKind: 'rhyme',
                            contentId: item.id,
                            trackType: 'targetNormal',
                            languageCode: 'sat',
                          );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncedLyrics(
    List<BakhedLyricLine> lyrics,
    ContentItem item,
    int positionMs,
    Color accentColor,
  ) {
    if (lyrics.isEmpty) {
      // Fallback: render the item's standard blocks (e.g. text/translation) in a premium way
      final textBlocks = item.blocks.whereType<TextBlock>().toList();
      if (textBlocks.isEmpty) {
        return Center(
          child: Text(
            'Lyrics are being added.',
            style: GoogleFonts.fredoka(color: Colors.white38, fontSize: 15),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: textBlocks.length,
        itemBuilder: (context, index) {
          final block = textBlocks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.textOlChiki != null &&
                    block.textOlChiki!.isNotEmpty) ...[
                  Text(
                    block.textOlChiki!,
                    style: const TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  block.textLatin ?? block.markdown,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Find the active lyric line index
    int activeIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      if (positionMs >= line.startMs && positionMs <= line.endMs) {
        activeIndex = i;
        break;
      }
    }
    if (activeIndex == -1) {
      for (int i = lyrics.length - 1; i >= 0; i--) {
        if (positionMs >= lyrics[i].endMs) {
          activeIndex = i;
          break;
        }
      }
    }

    // Smooth auto-scroll to center
    if (activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_lyricScrollController.hasClients && activeIndex >= 0) {
          final targetOffset = (activeIndex * 105.0) - 100.0;
          _lyricScrollController.animateTo(
            targetOffset.clamp(
              0.0,
              _lyricScrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    return ListView.builder(
      controller: _lyricScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == activeIndex;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref
                .read(rhymeAudioProvider.notifier)
                .seek(Duration(milliseconds: line.startMs));
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isActive ? 1.0 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 24.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isActive
                    ? Border.all(color: Colors.white.withOpacity(0.05))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.olChiki,
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: isActive ? 26 : 23,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line.latin,
                    style: GoogleFonts.inter(
                      fontSize: isActive ? 16 : 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  if (line.meaning.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      line.meaning,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
              style: GoogleFonts.fredoka(
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
                              style: GoogleFonts.fredoka(
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
                                style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                      GestureDetector(
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
                      const SizedBox(width: 24),
                      // Forward 10s
                      IconButton(
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
                        ),
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
