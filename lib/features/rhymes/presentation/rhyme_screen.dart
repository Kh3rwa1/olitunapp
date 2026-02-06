import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../domain/rhyme_model.dart';
import 'widgets/whimsical_audio_waves.dart';
import 'widgets/tilt_card.dart';
import 'widgets/whimsical_background.dart';

class RhymeScreen extends ConsumerWidget {
  const RhymeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rhymesAsync = ref.watch(rhymesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WhimsicalBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Santali Rhymes',
                        style: GoogleFonts.fredoka(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'PLAY & LEARN',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: isDark
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                    ],
                  ),
                ),
              ),

              // Featured Card
              rhymesAsync.when(
                data: (rhymes) => rhymes.isNotEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TiltCard(
                            child: _FeaturedRhymeCard(rhyme: rhymes.first),
                          ),
                        ),
                      )
                    : const SliverToBoxAdapter(child: SizedBox.shrink()),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'DISCOVER MORE',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Bento Grid
              rhymesAsync.when(
                data: (rhymes) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final rhymeIndex = index + 1;
                      if (rhymeIndex >= rhymes.length) return null;
                      return TiltCard(
                        child: _BentoRhymeCard(
                          rhyme: rhymes[rhymeIndex],
                          index: rhymeIndex,
                        ),
                      );
                    }, childCount: rhymes.isEmpty ? 0 : rhymes.length - 1),
                  ),
                ),
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedRhymeCard extends StatefulWidget {
  final RhymeModel rhyme;
  const _FeaturedRhymeCard({required this.rhyme});

  @override
  State<_FeaturedRhymeCard> createState() => _FeaturedRhymeCardState();
}

class _FeaturedRhymeCardState extends State<_FeaturedRhymeCard> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;

    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WhimsicalAudioWaves(
              isPlaying: _isPlaying,
              color: Colors.white.withOpacity(0.3),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32.0),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'FEATURED',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isPlaying
                          ? Icons.music_note_rounded
                          : Icons.music_off_rounded,
                      color: Colors.white70,
                    ).animate(target: _isPlaying ? 1 : 0).shake(),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.rhyme.titleLatin,
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  widget.rhyme.titleOlChiki,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    fontFamily: 'OlChiki',
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPlaying ? 'STOP' : 'LISTEN',
                              style: GoogleFonts.fredoka(
                                color: color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 2.seconds,
                    ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(curve: Curves.easeOutBack);
  }
}

class _BentoRhymeCard extends StatefulWidget {
  final RhymeModel rhyme;
  final int index;
  const _BentoRhymeCard({required this.rhyme, required this.index});

  @override
  State<_BentoRhymeCard> createState() => _BentoRhymeCardState();
}

class _BentoRhymeCardState extends State<_BentoRhymeCard> {
  bool _isPlaying = false;

  final List<Color> _palette = [
    AppColors.duoBlue,
    AppColors.duoGreen,
    AppColors.duoOrange,
    AppColors.duoRed,
    AppColors.duoYellow,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[widget.index % _palette.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.3 : 0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Waveform background when playing
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: WhimsicalAudioWaves(
                    isPlaying: _isPlaying,
                    color: color.withOpacity(0.2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(
                                      _getIconForCategory(
                                        widget.rhyme.category,
                                      ),
                                      color: color,
                                      size: 20,
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.2, 1.2),
                                      duration: 2.seconds,
                                    ),
                          ),
                          GestureDetector(
                                onTap: () =>
                                    setState(() => _isPlaying = !_isPlaying),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              )
                              .animate(target: _isPlaying ? 1 : 0)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                              ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.rhyme.titleLatin,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.rhyme.titleOlChiki,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontFamily: 'OlChiki',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (widget.index * 100).ms)
        .scale(curve: Curves.easeOutBack);
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'animal':
        return Icons.pets_rounded;
      case 'nature':
        return Icons.wb_sunny_rounded;
      case 'moral':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }
}
