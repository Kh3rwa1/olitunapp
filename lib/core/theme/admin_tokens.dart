import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AAA+ Admin Design Tokens
///
/// Centralised visual language for the admin panel. Every admin screen and
/// shared admin widget should source colours, surfaces, shadows, radii, type
/// styles, and spacing from this file so the panel reads as one cohesive,
/// premium product.
///
/// Rules of thumb:
///  * Olitun green (`AppColors.primary`) is reserved for emphasis, brand
///    moments, and the active state. Neutrals do most of the work.
///  * Surfaces are layered: [base] (page) → [raised] (cards / panels) →
///    [overlay] (dialogs, popovers) → [sunken] (inputs, code).
///  * Typography uses a real scale (display → mono) with intentional weights
///    and tracking. Avoid one-off `w900` / `letterSpacing: -2` everywhere.
///  * Both light and dark modes are designed equally; no token relies on one
///    mode to look good.
class AdminTokens {
  AdminTokens._();

  // ============== RADII ==============
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radius2xl = 36;

  // ============== SPACING ==============
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 56;
  static const double space10 = 72;

  // ============== NEUTRAL RAMPS ==============
  // Light mode neutrals — warm-cool slate, not pure grey, for premium depth.
  static const Color neutral25 = Color(0xFFFCFCFD); // overlay
  static const Color neutral50 = Color(0xFFF6F7F9); // raised on tint
  static const Color neutral75 = Color(0xFFEEF0F4); // base
  static const Color neutral100 = Color(0xFFE4E7EC);
  static const Color neutral200 = Color(0xFFCFD3DA);
  static const Color neutral300 = Color(0xFFA0A7B0);
  static const Color neutral400 = Color(0xFF6E747F);
  static const Color neutral500 = Color(0xFF4A4F58);
  static const Color neutral700 = Color(0xFF2A2E36);
  static const Color neutral800 = Color(0xFF1A1D23);
  static const Color neutral900 = Color(0xFF0E1116);
  static const Color neutral950 = Color(0xFF070A0F);

  // ============== SURFACES ==============
  // base = page background; raised = cards; overlay = dialogs; sunken = inputs.
  static Color base(bool isDark) =>
      isDark ? const Color(0xFF07090D) : neutral75;
  static Color baseTint(bool isDark) =>
      isDark ? const Color(0xFF0B0F15) : neutral50;
  static Color raised(bool isDark) =>
      isDark ? const Color(0xFF111621) : Colors.white;
  static Color raisedAlt(bool isDark) =>
      isDark ? const Color(0xFF161C29) : neutral25;
  static Color overlay(bool isDark) =>
      isDark ? const Color(0xFF1A2030) : Colors.white;
  static Color sunken(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.035);

  // Subtle border at the right opacity for both themes.
  static Color border(bool isDark, {double strength = 1}) => isDark
      ? Colors.white.withValues(alpha: 0.06 * strength)
      : Colors.black.withValues(alpha: 0.07 * strength);
  static Color borderStrong(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.12);
  static Color divider(bool isDark) => border(isDark, strength: 0.7);

  // ============== TEXT ==============
  static Color textPrimary(bool isDark) =>
      isDark ? const Color(0xFFF4F6FA) : const Color(0xFF0B1220);
  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xFFB7BECB) : const Color(0xFF4A5160);
  static Color textTertiary(bool isDark) =>
      isDark ? const Color(0xFF7A8294) : const Color(0xFF7A8294);
  static Color textMuted(bool isDark) =>
      isDark ? const Color(0xFF565E70) : const Color(0xFFA0A7B0);

  // ============== BRAND ==============
  static const Color accent = AppColors.primary;
  static Color accentSoft(bool isDark) => isDark
      ? AppColors.primary.withValues(alpha: 0.14)
      : AppColors.primary.withValues(alpha: 0.10);
  static Color accentBorder(bool isDark) =>
      AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28);

  // ============== SHADOWS ==============
  // Layered shadow used on raised cards. Designed to feel airy in light mode
  // and as a soft glow rim in dark mode.
  static List<BoxShadow> raisedShadow(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0B1220).withValues(alpha: 0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B1220).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
        ];

  static List<BoxShadow> overlayShadow(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0B1220).withValues(alpha: 0.08),
            blurRadius: 60,
            offset: const Offset(0, 24),
            spreadRadius: -12,
          ),
        ];

  static List<BoxShadow> brandGlow(Color color, {double strength = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30 * strength),
          blurRadius: 28 * strength,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];

  // ============== TYPOGRAPHY ==============
  // A real type scale — use these instead of ad-hoc fontSize / fontWeight.
  static TextStyle display(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 40,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary(isDark),
      );

  static TextStyle pageTitle(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: textPrimary(isDark),
      );

  static TextStyle sectionTitle(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary(isDark),
      );

  static TextStyle cardTitle(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: textPrimary(isDark),
      );

  static TextStyle body(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: textSecondary(isDark),
      );

  static TextStyle bodyStrong(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: textPrimary(isDark),
      );

  static TextStyle label(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: textSecondary(isDark),
      );

  static TextStyle eyebrow(bool isDark, {Color? color}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color ?? textTertiary(isDark),
      );

  static TextStyle metric(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 36,
        height: 1.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: textPrimary(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricSmall(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        height: 1.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: textPrimary(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
