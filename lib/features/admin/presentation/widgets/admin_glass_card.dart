import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/admin_tokens.dart';

/// AAA+ surface used across the admin panel. Defaults to a "raised" opaque
/// surface that reads as premium in both light and dark themes; opt into the
/// frosted-glass variant via [glass: true] for hero / overlay moments.
///
/// Public API is intentionally kept stable — every screen that already calls
/// `AdminGlassCard(child: ...)` automatically inherits the new look.
class AdminGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final double opacity;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? margin;

  /// When true, render the frosted-glass treatment (BackdropFilter +
  /// translucent fill). When false, render a clean raised card.
  final bool glass;

  /// When true, render with a subtle gradient sheen for hero moments.
  final bool elevated;

  const AdminGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AdminTokens.radiusXl,
    this.color,
    this.opacity = 0.06,
    this.blur = 20,
    this.boxShadow,
    this.border,
    this.alignment,
    this.glass = true,
    this.elevated = false,
  });

  @override
  State<AdminGlassCard> createState() => _AdminGlassCardState();
}

class _AdminGlassCardState extends State<AdminGlassCard> {
  bool _isHovered = false;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

    Widget cardContent;

    if (widget.glass) {
      cardContent = Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        alignment: widget.alignment,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: widget.boxShadow ?? AdminTokens.raisedShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: widget.color ??
                        (isDark
                            ? const Color(0xFF0F1622).withValues(alpha: 0.60)
                            : Colors.white.withValues(alpha: 0.75)),
                    borderRadius: radius,
                    border: widget.border ??
                        Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.09)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                  ),
                  child: widget.child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: GlowBorderPainter(
                        hoverPosition: _hoverPosition,
                        isHovered: _isHovered,
                        borderRadius: widget.borderRadius,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final fill = widget.color ?? AdminTokens.raised(isDark);
      cardContent = Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        alignment: widget.alignment,
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: fill,
          gradient: widget.elevated
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AdminTokens.raisedAlt(true), AdminTokens.raised(true)]
                      : [Colors.white, AdminTokens.neutral25],
                )
              : null,
          border: widget.border ?? Border.all(color: AdminTokens.border(isDark)),
          boxShadow: widget.boxShadow ?? AdminTokens.raisedShadow(isDark),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GlowBorderPainter(
                    hoverPosition: _hoverPosition,
                    isHovered: _isHovered,
                    borderRadius: widget.borderRadius,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      onHover: (event) => setState(() => _hoverPosition = event.localPosition),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: cardContent,
      ),
    );
  }
}

class GlowBorderPainter extends CustomPainter {
  final Offset? hoverPosition;
  final bool isHovered;
  final double borderRadius;
  final bool isDark;

  GlowBorderPainter({
    required this.hoverPosition,
    required this.isHovered,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHovered || hoverPosition == null) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AdminTokens.accent.withValues(alpha: isDark ? 0.35 : 0.25),
          AdminTokens.accent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
        center: Alignment(
          (hoverPosition!.dx / size.width) * 2 - 1,
          (hoverPosition!.dy / size.height) * 2 - 1,
        ),
        radius: 0.6,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GlowBorderPainter oldDelegate) {
    return oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark;
  }
}
