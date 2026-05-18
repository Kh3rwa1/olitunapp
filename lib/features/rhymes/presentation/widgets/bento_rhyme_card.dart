import 'dart:math' as math;
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

/// Bento-grid rhyme card with play toggle and mini visualizer.
class BentoRhymeCard extends ConsumerStatefulWidget {
  final RhymeModel rhyme;
  final int index;
  const BentoRhymeCard({super.key, required this.rhyme, required this.index});

  @override
  ConsumerState<BentoRhymeCard> createState() => _BentoRhymeCardState();
}

class _BentoRhymeCardState extends ConsumerState<BentoRhymeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconBounceController;

  @override
  void initState() {
    super.initState();
    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _iconBounceController.dispose();
    super.dispose();
  }

  static const List<Color> _palette = [
    AppColors.duoBlue,
    AppColors.duoGreen,
    AppColors.duoOrange,
    AppColors.duoRed,
    AppColors.duoYellow,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(rhymeAudioProvider);
    final isPlaying =
        audioState.playingRhymeId == widget.rhyme.id && audioState.isPlaying;
    final color = _palette[widget.index % _palette.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      blur: 12,
      borderRadius: 32,
      padding: EdgeInsets.zero,
      backgroundColor: isDark
          ? color.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.7),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 60,
              child: EnchantedVisualizer(
                isPlaying: isPlaying,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForCategory(widget.rhyme.category),
                            color: color,
                            size: 16,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .rotate(
                          begin: -0.03,
                          end: 0.03,
                          duration: 3.seconds,
                          curve: Curves.easeInOutSine,
                        ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _iconBounceController.forward(from: 0);
                        ref
                            .read(rhymeAudioProvider.notifier)
                            .togglePlay(
                              widget.rhyme.id,
                              widget.rhyme.audioUrl,
                              title: primaryTitle,
                              artworkUrl: widget.rhyme.thumbnailUrl,
                            );
                      },
                      child: AnimatedBuilder(
                        animation: _iconBounceController,
                        builder: (context, child) {
                          final bounce =
                              1.0 +
                              0.2 *
                                  math.sin(
                                    _iconBounceController.value * math.pi,
                                  ) *
                                  (1 - _iconBounceController.value);
                          return Transform.scale(scale: bounce, child: child);
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            key: ValueKey(isPlaying),
                            color: color,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.rhyme.subcategory != null)
                  Text(
                        widget.rhyme.subcategory?.toUpperCase() ?? '',
                        style: GoogleFonts.fredoka(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: 0.15),
                const SizedBox(height: 4),
                Text(
                      primaryTitle,
                      style:
                          (scriptMode == 'olchiki'
                                  ? const TextStyle(fontFamily: 'OlChiki')
                                  : GoogleFonts.fredoka())
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryDark,
                                height: 1.1,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutCubic),
                if (secondaryTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                        secondaryTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontFamily: 'OlChiki',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms)
                      .slideY(begin: 0.10, curve: Curves.easeOutCubic),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'sohrai':
        return Icons.agriculture_rounded;
      case 'baha':
        return Icons.local_florist_rounded;
      case 'mag\'more':
        return Icons.eco_rounded;
      case 'chhatyar':
        return Icons.child_friendly_rounded;
      case 'bapla':
        return Icons.favorite_rounded;
      case 'bhandan':
        return Icons.group_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}
