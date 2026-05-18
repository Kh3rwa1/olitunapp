import 'package:flutter/material.dart';

class OlChikiGlyphGuidePainter extends CustomPainter {
  final String character;
  final Color fillColor;
  final Color outlineColor;
  final double scale;

  const OlChikiGlyphGuidePainter({
    required this.character,
    required this.fillColor,
    required this.outlineColor,
    this.scale = 0.64,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (character.isEmpty) return;

    final fontSize = size.shortestSide * scale;
    final outlineStyle = TextStyle(
      fontFamily: 'OlChiki',
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.012
        ..strokeJoin = StrokeJoin.round
        ..color = outlineColor,
    );
    final fillStyle = TextStyle(
      fontFamily: 'OlChiki',
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1,
      color: fillColor,
    );

    _paintCenteredText(canvas, size, outlineStyle);
    _paintCenteredText(canvas, size, fillStyle);
  }

  void _paintCenteredText(Canvas canvas, Size size, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: character, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant OlChikiGlyphGuidePainter oldDelegate) {
    return oldDelegate.character != character ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.scale != scale;
  }
}
