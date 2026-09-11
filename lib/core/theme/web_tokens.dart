import 'package:flutter/material.dart';

/// Premium web / desktop design tokens.
///
/// Single source of truth for the $10B-agency web shell: canvas meshes,
/// glass surfaces, web-first shadows, radii and max-widths. Mobile code
/// paths must not import this — it is intentionally desktop-web biased
/// (hover, wide gutters, ambient orbs).
class WebTokens {
  WebTokens._();

  // ── Breakpoints ──────────────────────────────────────────────
  static const double wideBreakpoint = 1440;
  static const double maxCenterColumn = 880;
  static const double maxLessonCanvas = 780;
  static const double maxPlayerCanvas = 720;

  static const double leftRailWidth = 268;
  static const double rightRailWidth = 324;

  // ── Radii ────────────────────────────────────────────────────
  static const double radiusCard = 24;
  static const double radiusLarge = 28;
  static const double radiusPill = 999;

  // ── Canvas ───────────────────────────────────────────────────
  static const Color lightCanvas = Color(0xFFF4F6FB);
  static const Color lightCanvasWarm = Color(0xFFF8FAFF);
  static const Color darkCanvas = Color(0xFF070B13);
  static const Color darkCanvasMid = Color(0xFF0B1220);

  static const LinearGradient lightMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFF), Color(0xFFEFFDF4), Color(0xFFE8F6FF)],
  );

  static const LinearGradient darkMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070B13), Color(0xFF0B1A14), Color(0xFF0D1B2E)],
  );

  // Emerald mist orbs used by the ambient background.
  static const Color orbEmerald = Color(0xFF1EE088);
  static const Color orbSky = Color(0xFF38BDF8);
  static const Color orbViolet = Color(0xFF8B5CF6);

  // ── Surfaces ─────────────────────────────────────────────────
  static Color cardLight(bool isDark) =>
      isDark ? const Color(0xFF101724) : Colors.white;

  static Color cardBorderLight(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3E8F0);

  static List<BoxShadow> cardShadow(bool isDark, {Color? tint}) {
    if (isDark) {
      return const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 32,
          offset: Offset(0, 16),
          spreadRadius: -12,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 32,
        offset: const Offset(0, 16),
        spreadRadius: -16,
      ),
      BoxShadow(
        color: (tint ?? const Color(0xFF1EE088)).withValues(alpha: 0.06),
        blurRadius: 48,
        offset: const Offset(0, 12),
        spreadRadius: -20,
      ),
    ];
  }

  static List<BoxShadow> popShadow(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.35),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Glass ────────────────────────────────────────────────────
  static BoxDecoration glass(bool isDark, {double radius = radiusCard}) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.9),
      ),
      boxShadow: cardShadow(isDark),
    );
  }

  // ── Hero gradients ───────────────────────────────────────────
  static const LinearGradient emeraldHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C767), Color(0xFF00A355), Color(0xFF0B6B3A)],
  );

  static const LinearGradient emeraldCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1EE088), Color(0xFF00C767)],
  );

  static const LinearGradient inkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111C2E), Color(0xFF0B1220)],
  );

  // ── Type ─────────────────────────────────────────────────────
  static const double displayHome = 38;
  static const double displayHero = 42;

  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: color,
  );

  // ── Helpers ──────────────────────────────────────────────────
  static bool isWide(double width) => width >= wideBreakpoint;

  static EdgeInsets webPagePadding(bool isDesktop, bool isWide) {
    if (!isDesktop)
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    if (isWide) return const EdgeInsets.symmetric(horizontal: 44, vertical: 36);
    return const EdgeInsets.symmetric(horizontal: 36, vertical: 32);
  }
}
