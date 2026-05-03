import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion_tokens.dart';

/// A widget that tweens an integer from its previous value to the new
/// one whenever [value] changes. On every change it also briefly
/// scale-pulses to draw the eye and (optionally) fires a light haptic,
/// so a stat going up *feels* like an event rather than a silent
/// number swap.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = MotionTokens.medium,
    this.curve = MotionTokens.standard,
    this.prefix = '',
    this.suffix = '',
    this.haptic = true,
    this.pulseOnChange = true,
    this.textAlign,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final bool haptic;
  final bool pulseOnChange;
  final TextAlign? textAlign;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late int _from = widget.value;
  late int _to = widget.value;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: MotionTokens.medium,
  );

  late final Animation<double> _pulseAnim = Tween<double>(
    begin: 1.0,
    end: 1.18,
  ).chain(CurveTween(curve: MotionTokens.playfulSpring)).animate(_pulse);

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
      _to = widget.value;
      if (widget.pulseOnChange) {
        _pulse.forward(from: 0).then((_) {
          if (mounted) _pulse.reverse();
        });
      }
      if (widget.haptic && widget.value > oldWidget.value) {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = RespectMotion.duration(context, widget.duration);
    final curve = RespectMotion.curve(context, widget.curve);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulse.isAnimating || _pulse.value > 0 ? _pulseAnim.value : 1.0,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: _from.toDouble(), end: _to.toDouble()),
          duration: dur,
          curve: curve,
          builder: (_, v, __) => Text(
            '${widget.prefix}${v.round()}${widget.suffix}',
            style: widget.style,
            textAlign: widget.textAlign,
          ),
        ),
      ),
    );
  }
}
