import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Duration duration;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.1,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _onPointerMove(PointerEvent event, BoxConstraints constraints) {
    final x = event.localPosition.dx;
    final y = event.localPosition.dy;

    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;

    setState(() {
      _tiltX = (y - centerY) / centerY * widget.maxTilt;
      _tiltY = -(x - centerX) / centerX * widget.maxTilt;
    });
  }

  void _onPointerExit(PointerEvent event) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onPointerMove(e, constraints),
          onExit: _onPointerExit,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            transformAlignment: Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}
