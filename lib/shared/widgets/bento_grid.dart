import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single cell in a BentoGrid with configurable span and styling.
class BentoCell extends StatefulWidget {
  final int columnSpan;
  final int rowSpan;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool enableHover;

  const BentoCell({
    super.key,
    this.columnSpan = 1,
    this.rowSpan = 1,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.borderRadius = 28,
    this.boxShadow,
    this.border,
    this.enableHover = true,
  });

  @override
  State<BentoCell> createState() => _BentoCellState();
}

class _BentoCellState extends State<BentoCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: widget.padding,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          color: widget.color ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ??
              Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
          boxShadow: widget.boxShadow ??
              (isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Builds a responsive bento-style grid using Wrap for variable-sized cells.
/// Children must be BentoCell widgets.
class BentoGridLayout extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int columns;
  final double cellHeight;

  const BentoGridLayout({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.columns = 2,
    this.cellHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final cellWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            if (child is BentoCell) {
              final span = child.columnSpan.clamp(1, columns);
              final width = cellWidth * span + spacing * (span - 1);
              final height = cellHeight * child.rowSpan +
                  runSpacing * (child.rowSpan - 1);
              return SizedBox(width: width, height: height, child: child);
            }
            return SizedBox(width: cellWidth, height: cellHeight, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// Staggered bento animation wrapper
class AnimatedBentoChild extends StatelessWidget {
  final Widget child;
  final int index;
  final int delayMs;

  const AnimatedBentoChild({
    super.key,
    required this.child,
    required this.index,
    this.delayMs = 80,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: (index * delayMs).ms, duration: 500.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          delay: (index * delayMs).ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: (index * delayMs).ms,
          duration: 400.ms,
        );
  }
}
