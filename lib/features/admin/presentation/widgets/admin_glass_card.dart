import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/admin_tokens.dart';

/// AAA+ surface used across the admin panel. Defaults to a "raised" opaque
/// surface that reads as premium in both light and dark themes; opt into the
/// frosted-glass variant via [glass: true] for hero / overlay moments.
///
/// Public API is intentionally kept stable — every screen that already calls
/// `AdminGlassCard(child: ...)` automatically inherits the new look.
class AdminGlassCard extends StatelessWidget {
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

  /// When true, render the legacy frosted-glass treatment (BackdropFilter +
  /// translucent fill). When false (default), render a clean raised card.
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
    this.opacity = 0.05,
    this.blur = 18,
    this.boxShadow,
    this.border,
    this.alignment,
    this.glass = false,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    if (glass) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        alignment: alignment,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: boxShadow ?? AdminTokens.raisedShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color:
                    color ??
                    (isDark
                        ? Colors.white.withValues(alpha: opacity)
                        : Colors.white.withValues(alpha: 0.72)),
                borderRadius: radius,
                border:
                    border ??
                    Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.85),
                    ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    final fill = color ?? AdminTokens.raised(isDark);
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: fill,
        gradient: elevated
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AdminTokens.raisedAlt(true), AdminTokens.raised(true)]
                    : [Colors.white, AdminTokens.neutral25],
              )
            : null,
        border: border ?? Border.all(color: AdminTokens.border(isDark)),
        boxShadow: boxShadow ?? AdminTokens.raisedShadow(isDark),
      ),
      child: child,
    );
  }
}
