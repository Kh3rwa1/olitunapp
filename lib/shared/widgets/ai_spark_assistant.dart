import 'dart:async';
import 'dart:ui' show ImageFilter;

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
/// - Fullscreen mode: fills almost the entire screen with a massive,
///   interactive Lottie spark and frosted blur backdrop.
/// - Vanishes smoothly when processing completes.
class AiSparkAssistant extends StatefulWidget {
  const AiSparkAssistant({
    super.key,
    required this.statusText,
    this.subheadText,
    this.size = 130,
    this.compact = false,
    this.light = false,
    this.fullscreen = false,
    this.onTap,
    this.onDismiss,
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

  /// When true, renders almost full screen with a massive Lottie spark,
  /// frosted glass backdrop, and full-screen tap-to-interact behavior.
  final bool fullscreen;

  /// Optional callback invoked when the user interacts with the spark.
  final VoidCallback? onTap;

  /// Optional callback invoked when the user dismisses/minimizes fullscreen mode.
  final VoidCallback? onDismiss;

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
    '📜 Ol Chiki has 30 primary letters and 5 modifiers!',
    '🚀 Powered by cutting-edge neural models for Santali.',
    '✨ Keep tapping! You charged the AI with magical energy!',
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
    if (!kIsWeb &&
        Theme.of(context).platform != TargetPlatform.macOS &&
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

    if (widget.fullscreen) {
      return _buildFullscreen(isDark, primaryTextColor, secondaryTextColor);
    }

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
              _buildAura(widget.size * 0.85, isDark),
              _buildLottie(widget.size),
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
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
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
            _tapCount > 0
                ? _sparkTips[_tipIndex]
                : (widget.subheadText ?? 'Tap the AI Spark while you wait ✨'),
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
          _sparkBadge('⚡ Sparks: $_tapCount', primaryTextColor, 10, 8, 2),
        ],
      ],
    );
  }

  Widget _sparkBadge(
    String text,
    Color color,
    double fontSize,
    double hPad,
    double vPad,
  ) {
    final border = (widget.light ? Colors.white : AppColors.primary);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: border.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAura(double auraSize, bool isDark) {
    return Container(
      width: auraSize,
      height: auraSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (widget.light ? Colors.white : AppColors.primary).withValues(
              alpha: isDark ? 0.28 : 0.16,
            ),
            (widget.light ? AppColors.voiceTeal : AppColors.bakhedGlowBlue)
                .withValues(alpha: isDark ? 0.14 : 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildLottie(double size) {
    return Lottie.asset(
      'assets/animations/ai_spark.json',
      controller: _controller,
      onLoaded: _onCompositionLoaded,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size * 0.6,
        height: size * 0.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildFullscreen(
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxSparkHeight = (screenSize.height * 0.44).clamp(200.0, 420.0);
    final sparkSize = (screenSize.width * 0.80)
        .clamp(260.0, 360.0)
        .clamp(0.0, maxSparkHeight);

    return Material(
      color: Colors.transparent,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.studioAtmosphereDark.withValues(alpha: 0.94),
                        AppColors.studioCardDark.withValues(alpha: 0.96),
                        AppColors.studioAtmosphereDark.withValues(alpha: 0.98),
                      ]
                    : [
                        AppColors.lightBackground.withValues(alpha: 0.95),
                        AppColors.lightSurfaceVariant.withValues(alpha: 0.96),
                        AppColors.lightBackground.withValues(alpha: 0.98),
                      ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(child: _buildAura(sparkSize * 1.35, isDark)),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleTap,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? Colors.white
                                              : AppColors.primary)
                                          .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : AppColors.primary)
                                            .withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.success,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.success,
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI ASSISTANT ACTIVE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              MouseRegion(
                                onEnter: _onMouseEnter,
                                onExit: _onMouseExit,
                                cursor: SystemMouseCursors.click,
                                child: AnimatedScale(
                                  scale: _scale,
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOutBack,
                                  child: _buildLottie(sparkSize),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.statusText,
                                textAlign: TextAlign.center,
                                style: AppTypography.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Padding(
                                  key: ValueKey(
                                    'fullscreen-tip-$_tapCount-$_tipIndex',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    _tapCount > 0
                                        ? _sparkTips[_tipIndex]
                                        : (widget.subheadText ??
                                              'Tap anywhere on the screen to energize the AI ✨'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _tapCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      height: 1.4,
                                      color: _tapCount > 0
                                          ? (widget.light
                                                ? Colors.amberAccent
                                                : AppColors.amberEmber)
                                          : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _sparkBadge(
                                _tapCount > 0
                                    ? '⚡ $_tapCount Sparks Energized • Keep tapping!'
                                    : '✨ Tap anywhere to interact with Spark',
                                primaryTextColor,
                                12,
                                14,
                                6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.onDismiss != null)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 12,
                      child: Semantics(
                        label: 'Minimize AI Spark',
                        button: true,
                        child: IconButton(
                          onPressed: widget.onDismiss,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 28,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          tooltip: 'Minimize to background',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
