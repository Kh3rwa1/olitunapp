import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Studio playback phase driving the hero orb.
enum StudioPhase { idle, working, ready }

/// Hero strip: pulsing orb + title + live status line.
class StudioHeroStrip extends StatelessWidget {
  const StudioHeroStrip({
    super.key,
    required this.isDark,
    required this.phase,
    required this.playing,
    required this.statusText,
    this.big = false,
  });

  final bool isDark;
  final StudioPhase phase;
  final bool playing;
  final String statusText;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StudioOrb(phase: phase, playing: playing),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.santaliAiVoice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: big ? 30 : 21,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.accentPurpleDark,
                          AppColors.indigoVivid,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.newBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }
}

/// Pulsing gradient orb with a mic at its core — the "Lottie-like" motion
/// of the screen, hand-built so it needs no binary assets.
class StudioOrb extends StatefulWidget {
  const StudioOrb({super.key, required this.phase, required this.playing});

  final StudioPhase phase;
  final bool playing;

  @override
  State<StudioOrb> createState() => _StudioOrbState();
}

class _StudioOrbState extends State<StudioOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didUpdateWidget(covariant StudioOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final active = widget.phase == StudioPhase.working || widget.playing;
    if (active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.phase == StudioPhase.working || widget.playing;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Transform.scale(
                        scale:
                            0.75 +
                            (((_controller.value + i * 0.5) % 1.0) * 0.55),
                        child: Opacity(
                          opacity:
                              (1.0 - ((_controller.value + i * 0.5) % 1.0)) *
                              0.45,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.phase == StudioPhase.ready
                  ? const LinearGradient(
                      colors: [AppColors.voiceEmerald, AppColors.voiceTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [
                        AppColors.accentPurpleDark,
                        AppColors.indigoVivid,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.violetGlow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              widget.phase == StudioPhase.working
                  ? Icons.graphic_eq_rounded
                  : widget.phase == StudioPhase.ready && !widget.playing
                  ? Icons.check_rounded
                  : Icons.mic_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
