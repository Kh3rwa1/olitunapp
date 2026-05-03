import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'motion_tokens.dart';

/// Input wrapper: animated focus-glow + imperative shake() for
/// validation errors. Hold a `GlobalKey<FocusGlowFieldState>` and call
/// `key.currentState?.shake()` from your validator.
class FocusGlowField extends StatefulWidget {
  const FocusGlowField({
    super.key,
    required this.child,
    required this.focusNode,
    this.glowColor,
    this.borderRadius = 16,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final FocusNode focusNode;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<FocusGlowField> createState() => FocusGlowFieldState();
}

class FocusGlowFieldState extends State<FocusGlowField>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtl = AnimationController(
    vsync: this,
    duration: MotionTokens.short,
    value: widget.focusNode.hasFocus ? 1.0 : 0.0,
  );

  late final AnimationController _shakeCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _glowCtl.dispose();
    _shakeCtl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _glowCtl.forward();
    } else {
      _glowCtl.reverse();
    }
  }

  /// 3-cycle damped horizontal shake. Call after validation failure.
  void shake() {
    _shakeCtl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtl, _shakeCtl]),
      builder: (context, _) {
        final t = _shakeCtl.value;
        // 3 sine cycles in [0,1], damped by (1 - t).
        final dx = (1 - t) * 8 * math.sin(t * 3 * 2 * math.pi);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: AnimatedContainer(
            duration: MotionTokens.short,
            curve: MotionTokens.standard,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.32 * _glowCtl.value),
                  blurRadius: 18 * _glowCtl.value,
                  spreadRadius: 1.5 * _glowCtl.value,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
