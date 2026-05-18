import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../../shared/utils/localized_content.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/rhyme_model.dart';
import 'enchanted_visualizer.dart';

import '../providers/rhyme_audio_provider.dart';

/// Premium featured rhyme card with glassmorphism and audio visualizer.
class FeaturedRhymeCard extends ConsumerStatefulWidget {
  final RhymeModel rhyme;
  const FeaturedRhymeCard({super.key, required this.rhyme});

  @override
  ConsumerState<FeaturedRhymeCard> createState() => _FeaturedRhymeCardState();
}

class _FeaturedRhymeCardState extends ConsumerState<FeaturedRhymeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playPulseController;

  @override
  void initState() {
    super.initState();
    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _playPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isPlaying =
        audioState.playingRhymeId == widget.rhyme.id && audioState.isPlaying;
    const color = AppColors.primary;
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final primaryTitle = primaryLocalizedText(
      olChiki: widget.rhyme.titleOlChiki,
      latin: widget.rhyme.titleLatin,
      scriptMode: scriptMode,
    );
    final secondaryTitle = secondaryLocalizedText(
      olChiki: widget.rhyme.titleOlChiki,
      latin: widget.rhyme.titleLatin,
      scriptMode: scriptMode,
    );

    return GlassCard(
          blur: 24,
          borderRadius: 40,
          padding: EdgeInsets.zero,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EnchantedVisualizer(
                  isPlaying: isPlaying,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildBadge(
                              'FEATURED',
                              Colors.white.withValues(alpha: 0.2),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.3)
                            .scale(begin: const Offset(0.8, 0.8)),
                        if (widget.rhyme.subcategory != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                                widget.rhyme.subcategory?.toUpperCase() ?? '',
                                Colors.white.withValues(alpha: 0.1),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideX(begin: -0.3)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ],
                        const Spacer(),
                        PlayingIndicator(isPlaying: isPlaying),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                          primaryTitle,
                          style:
                              (scriptMode == 'olchiki'
                                      ? const TextStyle(fontFamily: 'OlChiki')
                                      : GoogleFonts.fredoka())
                                  .copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0,
                                    height: 1,
                                  ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideX(begin: -0.08, curve: Curves.easeOutCubic),
                    if (secondaryTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                            secondaryTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              fontFamily: 'OlChiki',
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 500.ms)
                          .slideX(begin: -0.06, curve: Curves.easeOutCubic),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _playPulseController.forward(from: 0);
                            ref
                                .read(rhymeAudioProvider.notifier)
                                .togglePlay(
                                  widget.rhyme.id,
                                  widget.rhyme.audioUrl,
                                  title: primaryTitle,
                                  artworkUrl: widget.rhyme.thumbnailUrl,
                                );
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                RotationTransition(
                                  turns: Tween(
                                    begin: 0.75,
                                    end: 1.0,
                                  ).animate(anim),
                                  child: ScaleTransition(
                                    scale: anim,
                                    child: child,
                                  ),
                                ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              color: color,
                            ),
                          ),
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              isPlaying ? 'PAUSE' : 'LISTEN NOW',
                              key: ValueKey(isPlaying),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                            shadowColor: Colors.black26,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.03, 1.03),
                          duration: 2.seconds,
                        )
                        .then()
                        .shimmer(
                          delay: 3.seconds,
                          duration: 1500.ms,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(autoPlay: false, onInit: (c) => c.forward())
        .fadeIn()
        .scale(curve: Curves.easeOutBack);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Animated equalizer bars shown when a rhyme is playing.
class PlayingIndicator extends StatefulWidget {
  final bool isPlaying;
  const PlayingIndicator({super.key, required this.isPlaying});

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _barControllers;
  final _barCount = 3;

  @override
  void initState() {
    super.initState();
    _barControllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 150),
      );
    });
    if (widget.isPlaying) _startBars();
  }

  @override
  void didUpdateWidget(PlayingIndicator old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _startBars() : _stopBars();
    }
  }

  void _startBars() {
    for (final c in _barControllers) {
      c.repeat(reverse: true);
    }
  }

  void _stopBars() {
    for (final c in _barControllers) {
      c.animateTo(0.2, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final c in _barControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: widget.isPlaying
          ? Container(
              key: const ValueKey('equalizer'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_barCount, (i) {
                  return AnimatedBuilder(
                    animation: _barControllers[i],
                    builder: (context, child) {
                      return Container(
                        width: 3,
                        height: 6 + _barControllers[i].value * 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
            )
          : Container(
                  key: const ValueKey('note'),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
    );
  }
}
