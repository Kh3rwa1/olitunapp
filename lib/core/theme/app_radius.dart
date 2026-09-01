import 'package:flutter/material.dart';

/// Semantic corner radius tokens across Olitun.
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 28.0;
  static const double full = 999.0;

  // BorderRadius presets
  static const BorderRadius borderZero = BorderRadius.zero;
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderXxxl = BorderRadius.all(
    Radius.circular(xxxl),
  );
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );

  // Top-only (e.g. bottom sheets)
  static const BorderRadius topLg = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius topXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius topXxl = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
  static const BorderRadius topXxxl = BorderRadius.vertical(
    top: Radius.circular(xxxl),
  );
}
