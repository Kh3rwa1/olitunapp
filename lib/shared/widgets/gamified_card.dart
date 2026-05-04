import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class GamifiedCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final Color? bottomBorderColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GamifiedCard({
    super.key,
    required this.child,
    this.color,
    this.bottomBorderColor,
    this.borderRadius = 18.0,
    this.borderWidth = 4.0,
    this.padding,
    this.onTap,
  });

  @override
  State<GamifiedCard> createState() => _GamifiedCardState();
}

class _GamifiedCardState extends State<GamifiedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.color ?? (isDark ? AppColors.darkSurfaceElevated : Colors.white);

    final borderColor =
        widget.bottomBorderColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.08));

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: widget.borderWidth),
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
