import 'package:flutter/material.dart';

/// Shared motion vocabulary (durations, curves, scales, hero-tag util).
class MotionTokens {
  MotionTokens._();

  static const Duration quick = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration long = Duration(milliseconds: 560);

  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve gentleSpring = Cubic(0.34, 1.32, 0.64, 1.0);
  static const Curve playfulSpring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve decelerate = Curves.easeOutQuart;

  static const double pressedScale = 0.96;
  static const double pressedScaleStrong = 0.94;

  static const Duration staggerStep = Duration(milliseconds: 60);
  static const Duration staggerMax = Duration(milliseconds: 480);

  static Duration staggerFor(int index) {
    final ms = (index * staggerStep.inMilliseconds).clamp(
      0,
      staggerMax.inMilliseconds,
    );
    return Duration(milliseconds: ms);
  }

  static String heroTag(String namespace, Object id) => 'hero/$namespace/$id';
}

/// Collapses durations/curves to no-op when the OS reduce-motion
/// setting is on.
class RespectMotion {
  static bool of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration duration(BuildContext context, Duration d) =>
      of(context) ? const Duration(milliseconds: 1) : d;

  static Curve curve(BuildContext context, Curve c) =>
      of(context) ? Curves.linear : c;
}
