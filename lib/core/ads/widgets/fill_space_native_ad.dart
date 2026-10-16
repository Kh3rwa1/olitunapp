import 'package:flutter/material.dart';

import 'native_ad_widget.dart';

/// Native ad for a flexible blank area (between a form and its action
/// button). Picks the medium template when the space fits it, the small one
/// when only that fits, and nothing otherwise, so it never squeezes the
/// layout. A gap on both sides keeps the ad clear of nearby buttons.
class FillSpaceNativeAd extends StatelessWidget {
  const FillSpaceNativeAd({
    super.key,
    required this.placement,
    this.accentColor,
    this.backgroundColor,
    this.cornerRadius = 20,
  });

  final String placement;
  final Color? accentColor;
  final Color? backgroundColor;
  final double cornerRadius;

  /// Ad height + the widget's own vertical margin (16) + [_gap] each side.
  static const double _gap = 12;
  static const double mediumNeeds = NativeAdWidget.mediumHeight + 16 + _gap * 2;
  static const double smallNeeds = 100 + 16 + _gap * 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final Widget ad;
        if (height >= mediumNeeds) {
          ad = NativeAdWidget.medium(
            key: const ValueKey('fill-space-medium'),
            placement: placement,
            accentColor: accentColor,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            pooled: true,
          );
        } else if (height >= smallNeeds) {
          ad = NativeAdWidget(
            key: const ValueKey('fill-space-small'),
            placement: placement,
            accentColor: accentColor,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            pooled: true,
          );
        } else {
          return const SizedBox.shrink();
        }
        return Center(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _gap),
              child: ad,
            ),
          ),
        );
      },
    );
  }
}
