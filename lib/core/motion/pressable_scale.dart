import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion_tokens.dart';

/// Tap wrapper: press-down scale + release spring + commit haptic.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = MotionTokens.pressedScale,
    this.haptic = HapticIntensity.light,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HapticIntensity haptic;
  final bool enabled;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.quick,
    reverseDuration: MotionTokens.short,
    value: 0.0,
  );

  late final Animation<double> _scaleAnim = Tween<double>(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: MotionTokens.standard,
    reverseCurve: MotionTokens.gentleSpring,
  ));

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (_interactive) _controller.forward();
  }

  void _release() {
    if (_interactive) _controller.reverse();
  }

  void _commit() {
    if (!_interactive || widget.onTap == null) return;
    _fireHaptic();
    widget.onTap!();
  }

  void _commitLong() {
    if (!_interactive || widget.onLongPress == null) return;
    HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case HapticIntensity.none:
        break;
      case HapticIntensity.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _interactive ? (_) => _press() : null,
      onTapUp: _interactive ? (_) => _release() : null,
      onTapCancel: _interactive ? _release : null,
      onTap: _interactive ? _commit : null,
      onLongPress: _interactive && widget.onLongPress != null
          ? _commitLong
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

enum HapticIntensity { none, selection, light, medium, heavy }
