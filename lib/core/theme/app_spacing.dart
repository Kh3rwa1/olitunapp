import 'package:flutter/material.dart';

/// Semantic spacing tokens across Olitun.
/// Scale based on harmonic grid:
/// - [xxs]:  2dp (micro-alignments)
/// - [xs]:   4dp (tight grouping)
/// - [sm]:   8dp (compact components)
/// - [md]:   12dp (card internals, chips)
/// - [lg]:   16dp (standard gutters, padding)
/// - [xl]:   20dp (expanded padding)
/// - [xxl]:  24dp (section spacing)
/// - [xxxl]: 32dp (page-level spacing)
/// - [huge]: 48dp (hero sections)
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // EdgeInsets presets
  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsXxl = EdgeInsets.all(xxl);

  // Horizontal presets
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical presets
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  // Combined Screen & Card presets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets screenPaddingWide = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  // SizedBox gap widgets
  static const Widget gapW4 = SizedBox(width: xs);
  static const Widget gapW8 = SizedBox(width: sm);
  static const Widget gapW12 = SizedBox(width: md);
  static const Widget gapW16 = SizedBox(width: lg);
  static const Widget gapW20 = SizedBox(width: xl);
  static const Widget gapW24 = SizedBox(width: xxl);
  static const Widget gapW32 = SizedBox(width: xxxl);

  static const Widget gapH4 = SizedBox(height: xs);
  static const Widget gapH8 = SizedBox(height: sm);
  static const Widget gapH12 = SizedBox(height: md);
  static const Widget gapH16 = SizedBox(height: lg);
  static const Widget gapH20 = SizedBox(height: xl);
  static const Widget gapH24 = SizedBox(height: xxl);
  static const Widget gapH32 = SizedBox(height: xxxl);
  static const Widget gapH48 = SizedBox(height: huge);
}
