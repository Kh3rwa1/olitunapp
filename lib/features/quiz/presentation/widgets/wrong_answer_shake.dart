import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/motion/motion.dart';

class WrongAnswerShake extends StatefulWidget {
  final Widget child;
  const WrongAnswerShake({super.key, required this.child});

  @override
  State<WrongAnswerShake> createState() => _WrongAnswerShakeState();
}

class _WrongAnswerShakeState extends State<WrongAnswerShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!RespectMotion.of(context)) {
        _ctl.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (RespectMotion.of(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, child) {
        final t = _ctl.value;
        final dx = (1 - t) * 8 * math.sin(t * 3 * 2 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
