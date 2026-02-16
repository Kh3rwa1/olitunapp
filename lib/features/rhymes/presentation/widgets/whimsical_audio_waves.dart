import 'dart:math' as math;
import 'package:flutter/material.dart';

class WhimsicalAudioWaves extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const WhimsicalAudioWaves({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<WhimsicalAudioWaves> createState() => _WhimsicalAudioWavesState();
}

class _WhimsicalAudioWavesState extends State<WhimsicalAudioWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WhimsicalAudioWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
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
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 40),
          painter: _WavePainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final Color color;

  _WavePainter({
    required this.animationValue,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = isPlaying ? 10.0 : 2.0;
    final speed = animationValue * 2 * math.pi;

    path.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height / 2 +
          math.sin(x * 0.05 + speed) * waveHeight +
          math.cos(x * 0.03 + speed * 1.5) * (waveHeight * 0.5);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second layer for depth
    final path2 = Path();
    final paint2 = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    path2.moveTo(0, size.height / 2 + 5);
    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height / 2 +
          math.cos(x * 0.04 + speed * 0.8) * waveHeight +
          math.sin(x * 0.02 + speed) * (waveHeight * 0.7);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
