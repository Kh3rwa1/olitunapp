import 'package:flutter/material.dart';

class CategoryTimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;
  final bool isDark;

  CategoryTimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.25 : 0.12)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double startY = isFirst ? 32.0 : 0.0;
    final double endY = isLast ? 32.0 : size.height;

    canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant CategoryTimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

class CategoryTimelineItem extends StatelessWidget {
  final Widget card;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final bool isLocked;
  final Color themeColor;
  final LinearGradient gradient;
  final Widget? stepNodeChild;

  const CategoryTimelineItem({
    super.key,
    required this.card,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.isLocked,
    required this.themeColor,
    required this.gradient,
    this.stepNodeChild,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 48,
            child: CustomPaint(
              painter: CategoryTimelinePainter(
                isFirst: isFirst,
                isLast: isLast,
                color: themeColor,
                isDark: isDark,
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 14,
                    child: CategoryStepNode(
                      index: index,
                      themeColor: themeColor,
                      isDark: isDark,
                      isLocked: isLocked,
                      gradient: gradient,
                      child: stepNodeChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Card Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryStepNode extends StatelessWidget {
  final int index;
  final Color themeColor;
  final bool isDark;
  final bool isLocked;
  final LinearGradient gradient;
  final Widget? child;

  const CategoryStepNode({
    super.key,
    required this.index,
    required this.themeColor,
    required this.isDark,
    required this.isLocked,
    required this.gradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.lock_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 14,
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF0A0E14) : Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child:
            child ??
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
      ),
    );
  }
}
