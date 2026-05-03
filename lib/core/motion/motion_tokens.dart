import 'package:flutter/material.dart';

/// Centralized motion vocabulary for the entire app.
///
/// Every animated surface should pull its durations, curves, and haptic
/// intensities from here so the app reads as one coherent product
/// rather than a patchwork of hand-tuned values.
class MotionTokens {
  MotionTokens._();

  // ── Durations ─────────────────────────────────────────────────────
  /// Snappy: button press feedback, ripple-style reactions.
  static const Duration quick = Duration(milliseconds: 120);

  /// Default: most state transitions, list-item enters, switchers.
  static const Duration short = Duration(milliseconds: 220);

  /// Medium: page-level transitions, hero flights, drawer opens.
  static const Duration medium = Duration(milliseconds: 360);

  /// Long: hero entrance moments, splash, big reveals.
  static const Duration long = Duration(milliseconds: 560);

  // ── Curves ────────────────────────────────────────────────────────
  /// Material 3 emphasized easing — for incoming primary content.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard ease for ambient state changes.
  static const Curve standard = Curves.easeOutCubic;

  /// A subtle overshoot that reads as "spring" without feeling cartoony.
  /// Equivalent to a critically damped spring response.
  static const Curve gentleSpring = Cubic(0.34, 1.32, 0.64, 1.0);

  /// Stronger overshoot for celebratory moments (correct answer, pulse).
  static const Curve playfulSpring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Decelerate-only curve, used for things sliding to rest.
  static const Curve decelerate = Curves.easeOutQuart;

  // ── Press feedback ────────────────────────────────────────────────
  /// Scale factor a tappable surface drops to while pressed.
  static const double pressedScale = 0.96;

  /// Smaller scale for chunky cards that need a more tactile feel.
  static const double pressedScaleStrong = 0.94;

  // ── List stagger ──────────────────────────────────────────────────
  /// Per-item delay when staggering a list-entrance animation.
  static const Duration staggerStep = Duration(milliseconds: 60);

  /// Cap on stagger total so long lists don't crawl.
  static const Duration staggerMax = Duration(milliseconds: 480);

  /// Returns the stagger delay for `index`, clamped to [staggerMax].
  static Duration staggerFor(int index) {
    final ms = (index * staggerStep.inMilliseconds)
        .clamp(0, staggerMax.inMilliseconds);
    return Duration(milliseconds: ms);
  }

  // ── Hero tags ─────────────────────────────────────────────────────
  /// Stable hero-tag generator. The id is interpolated rather than the
  /// raw entity passed to Hero so we never accidentally collide with
  /// another widget tree's hero of the same id.
  static String heroTag(String namespace, Object id) =>
      'hero/$namespace/$id';
}

/// Helper that collapses durations to ~zero when the OS reduce-motion
/// setting is on. All animated widgets in user-facing flows should
/// pipe their durations through this so accessibility settings are
/// respected without each widget tracking it independently.
class RespectMotion {
  /// True when the OS has requested reduced motion.
  static bool of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns 1ms when reduce-motion is on, otherwise [d].
  static Duration duration(BuildContext context, Duration d) =>
      of(context) ? const Duration(milliseconds: 1) : d;

  /// Returns [Curves.linear] when reduce-motion is on, otherwise [c].
  static Curve curve(BuildContext context, Curve c) =>
      of(context) ? Curves.linear : c;
}
