import 'package:flutter/material.dart';

/// A reusable accessibility wrapper that ensures a minimum touch target size
/// of 48x48 (Material Design standard) or custom size, with semantics and native ripple ink wells.
class MinimumTapTarget extends StatelessWidget {
  const MinimumTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.size = 48,
    this.borderRadius,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
