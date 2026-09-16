import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/web_tokens.dart';

void main() {
  group('WebTokens', () {
    test('defines stable layout dimensions and breakpoint behavior', () {
      expect(WebTokens.wideBreakpoint, 1440);
      expect(WebTokens.maxCenterColumn, 880);
      expect(WebTokens.maxLessonCanvas, 780);
      expect(WebTokens.maxPlayerCanvas, 720);
      expect(WebTokens.leftRailWidth, 268);
      expect(WebTokens.rightRailWidth, 324);
      expect(WebTokens.radiusCard, 24);
      expect(WebTokens.radiusLarge, 28);
      expect(WebTokens.radiusPill, 999);
      expect(WebTokens.displayHome, 38);
      expect(WebTokens.displayHero, 42);

      expect(WebTokens.isWide(WebTokens.wideBreakpoint - 0.1), isFalse);
      expect(WebTokens.isWide(WebTokens.wideBreakpoint), isTrue);
    });

    test('returns responsive page padding for each layout class', () {
      expect(
        WebTokens.webPagePadding(false, false),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      );
      expect(
        WebTokens.webPagePadding(true, false),
        const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      );
      expect(
        WebTokens.webPagePadding(true, true),
        const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
      );
    });

    test('builds light, dark, and tinted card surfaces', () {
      const customTint = Color(0xFF123456);

      expect(WebTokens.cardLight(false), Colors.white);
      expect(WebTokens.cardLight(true), const Color(0xFF101724));
      expect(WebTokens.cardBorderLight(false), const Color(0xFFE3E8F0));
      expect(
        WebTokens.cardBorderLight(true),
        Colors.white.withValues(alpha: 0.08),
      );

      final lightShadows = WebTokens.cardShadow(false);
      final darkShadows = WebTokens.cardShadow(true);
      final tintedShadows = WebTokens.cardShadow(false, tint: customTint);

      expect(lightShadows, hasLength(2));
      expect(darkShadows, hasLength(1));
      expect(darkShadows.single.color, const Color(0x66000000));
      expect(
        tintedShadows.last.color,
        customTint.withValues(alpha: 0.06),
      );
      expect(WebTokens.popShadow(customTint), hasLength(2));
    });

    test('builds glass decorations for both themes', () {
      final lightGlass = WebTokens.glass(false, radius: 30);
      final darkGlass = WebTokens.glass(true);

      expect(
        lightGlass.color,
        Colors.white.withValues(alpha: 0.72),
      );
      expect(lightGlass.borderRadius, BorderRadius.circular(30));
      expect(lightGlass.border, isA<Border>());
      expect(lightGlass.boxShadow, hasLength(2));

      expect(
        darkGlass.color,
        Colors.white.withValues(alpha: 0.04),
      );
      expect(
        darkGlass.borderRadius,
        BorderRadius.circular(WebTokens.radiusCard),
      );
      expect(darkGlass.border, isA<Border>());
      expect(darkGlass.boxShadow, hasLength(1));
    });

    test('publishes canvas, hero, and typography tokens', () {
      const customColor = Color(0xFFABCDEF);

      expect(WebTokens.lightCanvas, const Color(0xFFF4F6FB));
      expect(WebTokens.lightCanvasWarm, const Color(0xFFF8FAFF));
      expect(WebTokens.darkCanvas, const Color(0xFF070B13));
      expect(WebTokens.darkCanvasMid, const Color(0xFF0B1220));
      expect(WebTokens.orbEmerald, const Color(0xFF1EE088));
      expect(WebTokens.orbSky, const Color(0xFF38BDF8));
      expect(WebTokens.orbViolet, const Color(0xFF8B5CF6));
      expect(WebTokens.lightMesh.colors, hasLength(3));
      expect(WebTokens.darkMesh.colors, hasLength(3));
      expect(WebTokens.emeraldHero.colors, hasLength(3));
      expect(WebTokens.emeraldCard.colors, hasLength(2));
      expect(WebTokens.inkCard.colors, hasLength(2));

      final eyebrow = WebTokens.eyebrow(customColor);
      expect(eyebrow.fontFamily, 'Inter');
      expect(eyebrow.fontSize, 11);
      expect(eyebrow.fontWeight, FontWeight.w800);
      expect(eyebrow.letterSpacing, 1.8);
      expect(eyebrow.color, customColor);
    });
  });
}
