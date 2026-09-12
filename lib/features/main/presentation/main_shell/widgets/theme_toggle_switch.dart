import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animated sun/moon theme switch replacing the static segmented control.
///
/// Drives the two authored markers of `assets/animations/theme_toggle.json`
/// (LottieFiles "DarkLight interactive toggle", free license):
/// frames 0–90 morph light into dark, frames 91–180 morph back.
/// External theme changes (e.g. settings) animate to match; reduce-motion
/// jumps straight to the target frame. Falls back to a plain icon button
/// if the composition fails to load.
class AnimatedThemeToggle extends StatefulWidget {
  const AnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
    this.targetLabel,
  });

  /// Whether dark theme is currently active.
  final bool isDark;

  /// Called with the requested mode after the flip starts.
  final ValueChanged<bool> onToggle;

  /// Accessible label for the switch action (localized by the caller).
  final String? targetLabel;

  /// Composition frame counts of `theme_toggle.json`.
  static const double darkFrame = 90;
  static const double totalFrames = 180;

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late bool _showingDark = widget.isDark;

  @override
  void initState() {
    super.initState();
    _controller.value = widget.isDark
        ? AnimatedThemeToggle.darkFrame / AnimatedThemeToggle.totalFrames
        : 0.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDark != _showingDark) {
      _animateTo(widget.isDark);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateTo(bool dark) async {
    _showingDark = dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      setState(() {
        _controller.value = dark
            ? AnimatedThemeToggle.darkFrame / AnimatedThemeToggle.totalFrames
            : 1.0;
      });
      return;
    }
    if (dark) {
      _controller.value = 0.0;
      await _controller.animateTo(
        AnimatedThemeToggle.darkFrame / AnimatedThemeToggle.totalFrames,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _controller.value =
          (AnimatedThemeToggle.darkFrame + 1) / AnimatedThemeToggle.totalFrames;
      await _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
    if (mounted) setState(() {});
  }

  void _onTap() {
    final target = !_showingDark;
    _animateTo(target);
    widget.onToggle(target);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.targetLabel ?? 'Toggle theme',
      child: Tooltip(
        message: widget.targetLabel ?? 'Toggle theme',
        child: InkWell(
          key: const ValueKey('animated-theme-toggle'),
          onTap: _onTap,
          borderRadius: BorderRadius.circular(16),
          child: Lottie.asset(
            'assets/animations/theme_toggle.json',
            controller: _controller,
            animate: false,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              _showingDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
