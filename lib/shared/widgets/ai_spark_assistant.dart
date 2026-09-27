import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Interactive AI Assistant animation powered by Lottie.
///
/// Features:
/// - Smooth idle & hover floating animations while AI is processing.
/// - Interactive tap reaction: clicking/tapping triggers the spark click
///   burst animation (frames 142–200), haptic feedback, and dynamic
///   entertaining tips / Santali language tidbits so the user stays engaged.
/// - Mouse hover reaction on desktop/web (frames 84–126).
/// - Vanishes smoothly when processing completes.
class AiSparkAssistant extends StatefulWidget {
  const AiSparkAssistant({
    super.key,
    required this.statusText,
    this.subheadText,
    this.size = 130,
    this.compact = false,
    this.light = false,
    this.onTap,
  });

  /// Primary progress/status text (e.g. "Generating audio…", "Transcribing…").
  final String statusText;

  /// Optional secondary guidance or hint.
  final String? subheadText;

  /// Diameter of the animation asset.
  final double size;

  /// When true, renders in a tighter inline/dock layout.
  final bool compact;

  /// When true, styles text in bright white (for gradient cards like VoicePlayerFace).
  final bool light;

  /// Optional callback invoked when the user interacts with the spark.
  final VoidCallback? onTap;

  /// Total composition frames in `ai_spark.json`.
  static const double totalFrames = 393.0;
  static const double idleStart = 0.0;
  static const double idleEnd = 60.0 / totalFrames;
  static const double hoverLoopStart = 84.0 / totalFrames;
  static const double hoverLoopEnd = 126.0 / totalFrames;
  static const double clickStart = 142.0 / totalFrames;
  static const double clickEnd = 200.0 / totalFrames;

  @override
  State<AiSparkAssistant> createState() => _AiSparkAssistantState();
}

class _AiSparkAssistantState extends State<AiSparkAssistant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  LottieComposition? _composition;
  int _tapCount = 0;
  int _tipIndex = 0;
  bool _isHovered = false;
  bool _isClicking = false;
  double _scale = 1.0;

  static const List<String> _sparkTips = [
    '✨ Tap me to energize the AI!',
    '⚡ Neural engines running at full power…',
    '🌟 ᱥᱟᱱᱛᱟᱲᱤ ᱫᱚ ᱟᱹᱰᱤ ᱢᱚᱡᱽ (Santali is wonderful!)',
    '💡 1925: Guru Gomke Pandit Raghunath Murmu invented Ol Chiki!',
    '🎨 Converting your thoughts into rich Ol Chiki…',
    '💫 Almost there! Crafting your result with precision…',
    '🔥 Turbo spark charged! Polishing the output…',
  ];

  Timer? _bounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _bounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onCompositionLoaded(LottieComposition composition) {
    if (!mounted) return;
    _composition = composition;
    _controller.duration = composition.duration;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = AiSparkAssistant.idleEnd;
      return;
    }
    _playIdleLoop();
  }

  void _playIdleLoop() {
    if (!mounted || _isClicking) return;
    if (_isHovered) {
      _controller.repeat(
        min: AiSparkAssistant.hoverLoopStart,
        max: AiSparkAssistant.hoverLoopEnd,
      );
    } else {
      _controller.repeat(
        min: AiSparkAssistant.idleStart,
        max: AiSparkAssistant.hoverLoopEnd,
      );
    }
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    setState(() {
      _tapCount++;
      _tipIndex = (_tipIndex + 1) % _sparkTips.length;
      _scale = 0.92;
    });

    widget.onTap?.call();

    // Trigger bounce scale back to 1.0
    _bounceTimer?.cancel();
    _bounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _scale = 1.0);
    });

    final composition = _composition;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (composition != null && !reduceMotion) {
      _isClicking = true;
      try {
        _controller.value = AiSparkAssistant.clickStart;
        await _controller.animateTo(
          AiSparkAssistant.clickEnd,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // Ignored if cancelled
      } finally {
        _isClicking = false;
        if (mounted) _playIdleLoop();
      }
    }
  }

  void _onMouseEnter(PointerEnterEvent _) {
    if (!kIsWeb && Theme.of(context).platform != TargetPlatform.macOS &&
        Theme.of(context).platform != TargetPlatform.windows &&
        Theme.of(context).platform != TargetPlatform.linux) {
      return;
    }
    _isHovered = true;
    if (!_isClicking && _composition != null) {
      _controller.repeat(
        min: AiSparkAssistant.hoverLoopStart,
        max: AiSparkAssistant.hoverLoopEnd,
      );
    }
  }

  void _onMouseExit(PointerExitEvent _) {
    _isHovered = false;
    if (!_isClicking && _composition != null) {
      _playIdleLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = widget.light
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final secondaryTextColor = widget.light
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? Colors.white60 : Colors.black54);

    final animationWidget = MouseRegion(
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glowing aura backdrop
              Container(
                width: widget.size * 0.85,
                height: widget.size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (widget.light ? Colors.white : AppColors.primary)
                          .withValues(alpha: isDark ? 0.25 : 0.16),
                      (widget.light ? AppColors.voiceTeal : AppColors.bakhedGlowBlue)
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Lottie.asset(
                'assets/animations/ai_spark.json',
                controller: _controller,
                onLoaded: _onCompositionLoaded,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          animationWidget,
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                if (widget.subheadText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subheadText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        animationWidget,
        const SizedBox(height: 8),
        Text(
          widget.statusText,
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _tapCount > 0 ? _sparkTips[_tipIndex] : (widget.subheadText ?? 'Tap the AI Spark while you wait ✨'),
            key: ValueKey('spark-tip-$_tapCount-$_tipIndex'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: _tapCount > 0 ? FontWeight.w600 : FontWeight.w500,
              color: _tapCount > 0
                  ? (widget.light ? Colors.amberAccent : AppColors.amberEmber)
                  : secondaryTextColor,
            ),
          ),
        ),
        if (_tapCount > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (widget.light ? Colors.white : AppColors.primary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (widget.light ? Colors.white : AppColors.primary)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '⚡ Sparks: $_tapCount',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
