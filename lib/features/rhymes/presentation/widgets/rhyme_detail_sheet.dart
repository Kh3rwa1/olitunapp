import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isPlaying =
        audioState.playingRhymeId == widget.rhyme.id && audioState.isPlaying;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);
    final primaryTitle = primaryLocalizedText(
      olChiki: widget.rhyme.titleOlChiki,
      latin: widget.rhyme.titleLatin,
      scriptMode: scriptMode,
    );

    // Split lyrics by line
    final olChikiLines = widget.rhyme.contentOlChiki.split('\n');
    final latinLines = widget.rhyme.contentLatin.split('\n');
    final meanings = _rhymeMeanings[widget.rhyme.id] ?? const [];

    // Calculate current position value
    final currentPosition = _isDragging && _dragPositionSeconds != null
        ? Duration(seconds: _dragPositionSeconds!.toInt())
        : audioState.position;

    // Bound duration safely
    final totalDuration = audioState.duration.inSeconds > 0
        ? audioState.duration
        : const Duration(seconds: 1);
    final positionSeconds = currentPosition.inSeconds.toDouble().clamp(
      0.0,
      totalDuration.inSeconds.toDouble(),
    );

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

                const Divider(height: 1, thickness: 1),

                // Lyrics Content Section (Scrollable)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: latinLines.length,
                    itemBuilder: (context, index) {
                      final olChiki = index < olChikiLines.length
                          ? olChikiLines[index]
                          : '';
                      final latin = latinLines[index];
                      final meaning = index < meanings.length
                          ? meanings[index]
                          : 'Culture translation';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          children: [
                            // 1. Ol Chiki Text
                            if (olChiki.isNotEmpty)
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
                                  .fadeIn(delay: (index * 100).ms)
                                  .slideY(begin: 0.2),
                            const SizedBox(height: 6),
                            // 2. Latin Transliteration
                            Text(
                                  latin,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.black87,
                                    height: 1.2,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (index * 100 + 50).ms)
                                .slideY(begin: 0.15),
                            const SizedBox(height: 6),
                            // 3. English Meaning
                            Text(
                              meaning,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white38 : Colors.black38,
                                height: 1.2,
                              ),
                            ).animate().fadeIn(delay: (index * 100 + 100).ms),
                          ],
                        ),
                      );
                    },
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
                            _formatDuration(audioState.duration),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
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
