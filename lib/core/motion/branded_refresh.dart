import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Branded [RefreshIndicator]: same standard pull-to-refresh ergonomics
/// (so spinner state is driven by the gesture, not always-on), just
/// styled in the app's primary color with a slightly thicker stroke
/// and a deeper drop displacement.
class BrandedRefreshIndicator extends StatelessWidget {
  const BrandedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tint,
      backgroundColor: Theme.of(context).colorScheme.surface,
      strokeWidth: 2.8,
      displacement: 56,
      child: child,
    );
  }
}
