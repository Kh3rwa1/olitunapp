import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../shared/providers/bakhed_content_provider.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../../shared/utils/localized_content.dart';
import '../../domain/rhyme_model.dart';
import '../providers/rhyme_audio_provider.dart';

/// Dictionary maps for high fidelity line-by-line meanings of seed rhymes
const Map<String, List<String>> _rhymeMeanings = {
  'seed_1': [
    'Everything is cooked and ready',
    'All the paths of the forest are open',
  ],
  'seed_2': ['The tethered goat trap', 'Asking for a sickle'],
};

class BakhedVocab {
  final String olChiki;
  final String latin;
  final String english;
  final String pronunciation;

  const BakhedVocab({
    required this.olChiki,
    required this.latin,
    required this.english,
    required this.pronunciation,
  });
}

const Map<String, List<BakhedVocab>> _rhymeVocab = {
  'seed_1': [
    BakhedVocab(
      olChiki: 'ᱫᱟᱠᱟ',
      latin: 'Daka',
      english: 'Cooked Rice',
      pronunciation: '[dah-kah]',
    ),
    BakhedVocab(
      olChiki: 'ᱵᱤᱨ',
      latin: 'Bir',
      english: 'Forest',
      pronunciation: '[beer]',
    ),
    BakhedVocab(
      olChiki: 'ᱦᱚᱨ',
      latin: 'Hor',
      english: 'Path / Way',
      pronunciation: '[hor]',
    ),
    BakhedVocab(
      olChiki: 'ᱥᱤᱧ',
      latin: 'Siñ',
      english: 'Day',
      pronunciation: '[seen]',
    ),
  ],
  'seed_2': [
    BakhedVocab(
      olChiki: 'ᱢᱮᱨᱚᱢ',
      latin: 'Merom',
      english: 'Goat',
      pronunciation: '[may-rom]',
    ),
    BakhedVocab(
      olChiki: 'ᱫᱟᱛᱨᱚᱢ',
      latin: 'Datrom',
      english: 'Sickle',
      pronunciation: '[daht-rom]',
    ),
    BakhedVocab(
      olChiki: 'ᱜᱷᱟᱥ',
      latin: 'Ghas',
      english: 'Grass',
      pronunciation: '[ghahs]',
    ),
    BakhedVocab(
      olChiki: 'ᱥᱤᱭᱩᱜ',
      latin: 'Siyug',
      english: 'Ploughing',
      pronunciation: '[see-yoog]',
    ),
  ],
};

const Map<String, String> _rhymeCulture = {
  'seed_1':
      'In Santali traditional culture, the forest (Bir) is considered a sacred living deity and the source of life. Opening forest paths symbolises spiritual freedom, abundance, and the connection between the tribe and nature. This rhyme is traditionally chanted during hunting festivals or community gatherings to wish for peace and safe travels.',
  'seed_2':
      'Agricultural tools like the Datrom (sickle) hold deep economic and religious value in Santal households. Chants asking for sickle or tools represent the invocation of harvest deities and the industriousness of the community, reminding youngsters of the value of collective farming work.',
};

enum LyricMode { olChiki, latin }

class RhymeDetailSheet extends ConsumerStatefulWidget {
  final RhymeModel rhyme;

  const RhymeDetailSheet({super.key, required this.rhyme});

  @override
  ConsumerState<RhymeDetailSheet> createState() => _RhymeDetailSheetState();

  /// Static helper to display the sheet easily
  static void show(BuildContext context, RhymeModel rhyme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => RhymeDetailSheet(rhyme: rhyme),
    );
  }
}

class _RhymeDetailSheetState extends ConsumerState<RhymeDetailSheet> {
  double? _dragPositionSeconds;
  bool _isDragging = false;
  LyricMode _lyricMode = LyricMode.latin;
  bool _didApplyInitialLyricMode = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isCurrentBakhed = audioState.playingRhymeId == widget.rhyme.id;
    final isPlaying = isCurrentBakhed && audioState.isPlaying;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scriptMode = ref.watch(effectiveScriptModeProvider);
    if (!_didApplyInitialLyricMode) {
      _didApplyInitialLyricMode = true;
      _lyricMode = scriptMode == 'olchiki'
          ? LyricMode.olChiki
          : LyricMode.latin;
    }
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final bakhedContent =
        ref.watch(bakhedLearningContentProvider(widget.rhyme.id)).valueOrNull ??
        BakhedLearningContent.empty;
    final primaryTitle = primaryLocalizedText(
      olChiki: widget.rhyme.titleOlChiki,
      latin: widget.rhyme.titleLatin,
      scriptMode: scriptMode,
    );

    // Split lyrics by line
    final remoteLyrics = bakhedContent.lyrics;
    final olChikiLines = remoteLyrics.isNotEmpty
        ? remoteLyrics.map((line) => line.olChiki).toList()
        : widget.rhyme.contentOlChiki.split('\n');
    final latinLines = remoteLyrics.isNotEmpty
        ? remoteLyrics.map((line) => line.latin).toList()
        : widget.rhyme.contentLatin.split('\n');
    final lyricLineCount = olChikiLines.length > latinLines.length
        ? olChikiLines.length
        : latinLines.length;
    final meanings = remoteLyrics.isNotEmpty
        ? remoteLyrics.map((line) => line.meaning).toList()
        : _rhymeMeanings[widget.rhyme.id] ?? const <String>[];
    final vocabList = bakhedContent.vocabulary.isNotEmpty
        ? bakhedContent.vocabulary
              .where((item) => item.olChiki.isNotEmpty || item.latin.isNotEmpty)
              .map(
                (item) => BakhedVocab(
                  olChiki: item.olChiki,
                  latin: item.latin,
                  english: item.meaning,
                  pronunciation: item.audioFileId.isNotEmpty
                      ? 'Audio available'
                      : '',
                ),
              )
              .toList()
        : _rhymeVocab[widget.rhyme.id] ?? const <BakhedVocab>[];
    final remoteCultureNotes = bakhedContent.culturalNotes
        .where((note) => note.body.isNotEmpty)
        .toList(growable: false);
    final remoteCulture = remoteCultureNotes.isNotEmpty
        ? remoteCultureNotes.first
        : null;
    final cultureText = remoteCulture?.body ?? _rhymeCulture[widget.rhyme.id];
    final cultureTitle = remoteCulture != null && remoteCulture.title.isNotEmpty
        ? remoteCulture.title
        : 'CULTURAL NOTE';

    // Calculate current position value
    final currentPosition = _isDragging && _dragPositionSeconds != null
        ? Duration(seconds: _dragPositionSeconds!.toInt())
        : isCurrentBakhed
        ? audioState.position
        : Duration.zero;

    // Bound duration safely
    final totalDuration = isCurrentBakhed && audioState.duration.inSeconds > 0
        ? audioState.duration
        : const Duration(seconds: 1);
    final positionSeconds = currentPosition.inSeconds.toDouble().clamp(
      0.0,
      totalDuration.inSeconds.toDouble(),
    );
    final listenedPercent = totalDuration.inMilliseconds > 1000
        ? ((currentPosition.inMilliseconds / totalDuration.inMilliseconds) *
                  100)
              .round()
              .clamp(0, 100)
        : 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1424).withValues(alpha: 0.95)
            : const Color(0xFFFAF9F6).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Top Header (Rhyme title & category)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryTitle,
                              style:
                                  (scriptMode == 'olchiki'
                                          ? const TextStyle(
                                              fontFamily: 'OlChiki',
                                            )
                                          : GoogleFonts.fredoka())
                                      .copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.primaryDark,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.rhyme.category != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.rhyme.category!.toUpperCase(),
                                style: GoogleFonts.fredoka(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lyric Mode Sliding Toggles (Touch Target >= 48dp)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ...LyricMode.values.map((mode) {
                          final isSelected = _lyricMode == mode;
                          String label = '';
                          switch (mode) {
                            case LyricMode.olChiki:
                              label = 'Ol Chiki';
                              break;
                            case LyricMode.latin:
                              label = 'Latin';
                              break;
                          }
                          return Expanded(
                            child: PressableScale(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _lyricMode = mode;
                                });
                              },
                              child: Container(
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  label,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Lyrics Content & Bento Extensions Section (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lyrics presentation
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lyricLineCount,
                          itemBuilder: (context, index) {
                            final olChiki = index < olChikiLines.length
                                ? olChikiLines[index]
                                : '';
                            final latin = index < latinLines.length
                                ? latinLines[index]
                                : '';
                            final meaning = index < meanings.length
                                ? meanings[index]
                                : 'Culture translation';

                            final displayOlChiki =
                                _lyricMode == LyricMode.olChiki;
                            final displayLatin = _lyricMode == LyricMode.latin;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: Column(
                                children: [
                                  // 1. Ol Chiki Text
                                  if (olChiki.isNotEmpty && displayOlChiki)
                                    Text(
                                          olChiki,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'OlChiki',
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            height: 1.3,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: (index * 80).ms)
                                        .slideY(begin: 0.15),
                                  if (olChiki.isNotEmpty &&
                                      displayOlChiki &&
                                      displayLatin)
                                    const SizedBox(height: 6),
                                  // 2. Latin Transliteration
                                  if (latin.isNotEmpty && displayLatin)
                                    Text(
                                          latin,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : Colors.black87,
                                            height: 1.2,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: (index * 80 + 30).ms)
                                        .slideY(begin: 0.1),
                                  // 3. English Meaning
                                  const SizedBox(height: 6),
                                  Text(
                                    meaning,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      height: 1.2,
                                    ),
                                  ).animate().fadeIn(
                                    delay: (index * 80 + 60).ms,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        if (vocabList.isNotEmpty || cultureText != null) ...[
                          const Divider(height: 48, thickness: 1),
                        ],

                        // Extracted Vocabulary Section
                        if (vocabList.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'WORDS FROM THIS BAKHED',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black.withValues(alpha: 0.6),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 132,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: vocabList.length,
                              separatorBuilder: (context, i) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return VocabCard(
                                  vocab: vocabList[index],
                                  isDark: isDark,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Cultural Context Note Card
                        if (cultureText != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.white.withValues(alpha: 0.05),
                                        Colors.white.withValues(alpha: 0.02),
                                      ]
                                    : [
                                        Colors.white,
                                        Colors.amber.shade50.withValues(
                                          alpha: 0.3,
                                        ),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.library_books_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      cultureTitle.toUpperCase(),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cultureText,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Audio Controls Section
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C101C) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seek duration slider
                      Row(
                        children: [
                          Text(
                            _formatDuration(currentPosition),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.06),
                                thumbColor: AppColors.primary,
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                overlayColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                max: totalDuration.inSeconds.toDouble(),
                                value: positionSeconds,
                                onChanged: (val) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragPositionSeconds = val;
                                  });
                                },
                                onChangeEnd: (val) async {
                                  HapticFeedback.lightImpact();
                                  await ref
                                      .read(rhymeAudioProvider.notifier)
                                      .seek(Duration(seconds: val.toInt()));
                                  setState(() {
                                    _isDragging = false;
                                    _dragPositionSeconds = null;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(
                              isCurrentBakhed
                                  ? audioState.duration
                                  : Duration.zero,
                            ),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        label:
                            'Listening progress $listenedPercent percent. Complete 80 percent to count for today mission.',
                        child: Row(
                          children: [
                            Icon(
                              listenedPercent >= 80
                                  ? Icons.check_circle_rounded
                                  : Icons.headphones_rounded,
                              size: 16,
                              color: listenedPercent >= 80
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                listenedPercent >= 80
                                    ? 'Listening: $listenedPercent% • counts for today'
                                    : 'Listening: $listenedPercent% • complete 80% to count',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Premium Spotify/Apple Music playback controls
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle (Decorative/premium)
                          IconButton(
                            onPressed: HapticFeedback.selectionClick,
                            icon: const Icon(Icons.shuffle_rounded),
                            color: isDark ? Colors.white30 : Colors.black26,
                            iconSize: 22,
                          ),
                          // Skip Back
                          IconButton(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              final target =
                                  currentPosition - const Duration(seconds: 10);
                              final clampedTarget = target < Duration.zero
                                  ? Duration.zero
                                  : target;
                              await ref
                                  .read(rhymeAudioProvider.notifier)
                                  .seek(clampedTarget);
                            },
                            icon: const Icon(Icons.replay_10_rounded),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black87,
                            iconSize: 28,
                          ),
                          // Main Play/Pause (Big target >= 48dp)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              ref
                                  .read(rhymeAudioProvider.notifier)
                                  .togglePlay(
                                    widget.rhyme.id,
                                    widget.rhyme.audioUrl,
                                    title: primaryTitle,
                                    artworkUrl: widget.rhyme.thumbnailUrl,
                                  );
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          // Skip Forward
                          IconButton(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              final target =
                                  currentPosition + const Duration(seconds: 10);
                              final clampedTarget = target > totalDuration
                                  ? totalDuration
                                  : target;
                              await ref
                                  .read(rhymeAudioProvider.notifier)
                                  .seek(clampedTarget);
                            },
                            icon: const Icon(Icons.forward_10_rounded),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black87,
                            iconSize: 28,
                          ),
                          // Repeat (Decorative/premium)
                          IconButton(
                            onPressed: HapticFeedback.selectionClick,
                            icon: const Icon(Icons.repeat_rounded),
                            color: isDark ? Colors.white30 : Colors.black26,
                            iconSize: 22,
                          ),
                        ],
                      ),

                      // CTA Bridge back to related vocabulary/lessons (touch target >= 48dp)
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              ref.read(shellTabIndexProvider.notifier).state =
                                  0;
                              context.go('/');
                            },
                            icon: const Icon(Icons.menu_book_rounded, size: 20),
                            label: Text(
                              'BRIDGE TO LESSONS & VOCABULARY',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : AppColors.primaryDark,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                ),
                              ),
                            ),
                          )
                          .animate(
                            onPlay: reduceVisualEffects
                                ? null
                                : (c) => c.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.02, 1.02),
                            duration: 2500.ms,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VocabCard extends StatefulWidget {
  final BakhedVocab vocab;
  final bool isDark;

  const VocabCard({super.key, required this.vocab, required this.isDark});

  @override
  State<VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<VocabCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final meaning = widget.vocab.english.trim().isEmpty
        ? 'Meaning coming soon'
        : widget.vocab.english.trim();
    final pronunciation = widget.vocab.pronunciation.trim();
    return PressableScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _revealed = !_revealed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 144,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _revealed
                ? AppColors.primary
                : (widget.isDark
                      ? Colors.white10
                      : AppColors.primary.withValues(alpha: 0.12)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _revealed
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.vocab.olChiki,
              style: const TextStyle(
                fontFamily: 'OlChiki',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.vocab.latin,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Tap to reveal',
                  style: GoogleFonts.fredoka(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              secondChild: Column(
                children: [
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                    ),
                  ),
                  if (pronunciation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      pronunciation,
                      style: GoogleFonts.fredoka(
                        fontSize: 10,
                        color: widget.isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
              crossFadeState: _revealed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
