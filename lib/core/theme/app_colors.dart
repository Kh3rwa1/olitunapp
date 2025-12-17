import 'package:flutter/material.dart';

/// Olitun App Colors - $20B Startup Premium Design System
/// Inspired by Duolingo's playfulness + Stripe's sophistication
class AppColors {
  AppColors._();

  // ============== PRIMARY BRAND COLORS ==============
  // Electric Cyan - The signature Olitun color
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryLight = Color(0xFF5EFCE8);
  static const Color primaryDark = Color(0xFF00A385);
  
  // Deep Ocean - Premium depth
  static const Color secondary = Color(0xFF0A2463);
  static const Color secondaryLight = Color(0xFF1E3A8A);
  static const Color secondaryDark = Color(0xFF050F2C);

  // ============== ACCENT COLORS ==============
  // Vibrant accents for gamification & celebrations
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentMint = Color(0xFF34D399);

  // ============== SEMANTIC COLORS ==============
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // ============== LIGHT MODE ==============
  static const Color lightBackground = Color(0xFFFAFBFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);

  // ============== DARK MODE ==============
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkBorderSubtle = Color(0xFF1F2937);

  // ============== TEXT COLORS ==============
  // Light mode text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  // Dark mode text
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);
  static const Color textDisabledDark = Color(0xFF6B7280);

  // ============== PREMIUM GRADIENTS ==============
  
  // Hero gradients - Show-stopping, magazine-cover quality
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF00A385), Color(0xFF0A2463)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5EFCE8), Color(0xFF00D4AA)],
  );

  // Premium card gradients
  static const LinearGradient premiumCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00F5D4), Color(0xFF00BBF9)],
  );

  static const LinearGradient premiumPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  );

  static const LinearGradient premiumPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
  );

  static const LinearGradient premiumOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
  );

  static const LinearGradient premiumMint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6EE7B7), Color(0xFF34D399)],
  );

  static const LinearGradient premiumCoral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
  );

  // Mesh gradients for backgrounds
  static const LinearGradient meshLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0FDFA),
      Color(0xFFFAFBFC),
      Color(0xFFFDF4FF),
    ],
  );

  static const LinearGradient meshDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B1120),
      Color(0xFF111827),
      Color(0xFF1A1033),
    ],
  );

  // Dark mode card gradients
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
  );

  // Banner/Feature gradients
  static const LinearGradient skyBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF0EA5E9)],
  );

  static const LinearGradient peachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFFF97316)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE68A), Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFECACA), Color(0xFFF87171), Color(0xFFEF4444)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA7F3D0), Color(0xFF6EE7B7), Color(0xFF34D399)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDDD6FE), Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  );

  // Category gradients - Vibrant and distinct
  static const List<LinearGradient> categoryGradients = [
    premiumCyan,
    premiumPurple,
    premiumMint,
    premiumOrange,
    premiumPink,
    premiumCoral,
  ];

  // ============== GLASS MORPHISM ==============
  static Color glassWhite = Colors.white.withValues(alpha: 0.12);
  static Color glassBorder = Colors.white.withValues(alpha: 0.18);
  static Color glassWhiteDark = Colors.white.withValues(alpha: 0.06);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.08);
  
  // Premium glass effect
  static Color glassPremium = Colors.white.withValues(alpha: 0.85);
  static Color glassPremiumDark = const Color(0xFF1F2937).withValues(alpha: 0.90);

  // ============== SHADOWS ==============
  // Subtle - for base cards
  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Soft - for elevated cards
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // Medium - for floating elements
  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Large - for modals and overlays
  static List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 48,
      offset: const Offset(0, 24),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // Colored glow shadows
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Premium button shadow
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // For backward compatibility
  static const Color primaryCyan = primary;
  static const Color primaryTeal = primaryDark;
  static const Color primaryDeep = secondary;
  static const Color accentGold = accentYellow;
  static const Color accentPeach = Color(0xFFFFB4A2);
  static LinearGradient primaryGradient = heroGradientAlt;

  static List<BoxShadow> coloredShadow(Color color) => glowShadow(color);
}
