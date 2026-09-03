import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// An infinite, very subtle "breathing" scale loop (1.0 -> [maxScale] -> 1.0)
/// for idle emphasis: streak flames, CTA icons, and other quiet callouts.
///
/// Self-honoring: collapses to a static child when the OS reduce-motion
/// setting is on, or when [enabled] is false.
class BreathingPulse extends StatefulWidget {
  const BreathingPulse({
    super.key,
    required this.child,
    this.maxScale = 1.06,
    this.period = const Duration(milliseconds: 2200),
    this.enabled = true,
  });

  final Widget child;
  final double maxScale;
  final Duration period;
  final bool enabled;

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.maxScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool _reduced = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.duration = RespectMotion.duration(context, widget.period);
    if (widget.enabled && !_reduced && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = RespectMotion.duration(context, widget.period);
    }
    final shouldRun = widget.enabled && !_reduced;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _reduced) return widget.child;
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
