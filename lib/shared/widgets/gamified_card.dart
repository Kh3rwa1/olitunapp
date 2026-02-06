import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A playful, "Duo-style" card with a 3D pressed effect.
/// Features a thick bottom border that simulates depth.
class GamifiedCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        color ?? (isDark ? AppColors.darkSurfaceElevated : Colors.white);

    // Shadow color for the 3D effect
    final borderColor =
        bottomBorderColor ??
        (isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.08));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // The "3D" shadow/side part
        decoration: BoxDecoration(
          color: borderColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          // Shift the main content UP to create the 3D look
          margin: EdgeInsets.only(bottom: borderWidth),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
