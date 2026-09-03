import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// Pops its child in with a playful spring (scale 0 -> 1 + fade) and
/// replays the pop whenever [trigger] changes.
///
/// Ideal for checkmarks completing, badges appearing, and counts changing:
///
/// ```dart
/// SpringPop(
///   trigger: isDone,
///   child: Icon(Icons.check_rounded),
/// )
/// ```
///
/// Honors the OS reduce-motion setting automatically: when animations are
/// disabled the child renders statically at full scale/opacity.
class SpringPop extends StatefulWidget {
  const SpringPop({
    super.key,
    required this.trigger,
    required this.child,
    this.duration = MotionTokens.medium,
    this.curve = MotionTokens.playfulSpring,
    this.beginScale = 0.4,
    this.enabled = true,
  });

  /// The pop replays whenever this value changes (e.g. a completed bool,
  /// a counter, or the identity of an item).
  final Object trigger;
  final Widget child;
  final Duration duration;
  final Curve curve;

  /// Starting scale of the pop; 0.4 keeps the overshoot playful but subtle.
  final double beginScale;

  /// Set false to render statically (e.g. per-user "reduce visual effects").
  final bool enabled;

  @override
  State<SpringPop> createState() => _SpringPopState();
}

class _SpringPopState extends State<SpringPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.duration = RespectMotion.duration(context, widget.duration);
    if (!widget.enabled || _reduced) {
      _controller.value = 1; // settled, static
    } else if (_controller.value == 1 && !_everPlayed) {
      _controller.value = 0;
      _everPlayed = true;
      _controller.forward();
    }
  }

  bool _everPlayed = false;

  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
  );

  @override
  void didUpdateWidget(covariant SpringPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _replay();
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = RespectMotion.duration(context, widget.duration);
    }
  }

  void _replay() {
    if (!widget.enabled || _reduced) {
      // Jump straight to the settled state — no motion.
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
