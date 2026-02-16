import 'package:flutter/material.dart';

/// Olitun App Colors - Premium Green/White/Black Design System
/// Derived from the Olitun logo: Vibrant Mint Green (#1EE088)
/// Inspired by Spotify's boldness + Apple's elegance + Duolingo's playfulness
class AppColors {
  AppColors._();

  // ============== PRIMARY BRAND COLORS ==============
  // Signature Olitun Green (extracted from logo)
  static const Color primary = Color(0xFF1EE088); // Exact logo green
  static const Color primaryLight = Color(0xFF5DFFA8); // Lighter tint
  static const Color primaryDark = Color(
    0xFF00C767,
  ); // Deeper green (Used for 3D shadow)
  static const Color primaryMuted = Color(0xFF1EE088);

  // Playful Gamified Accents (Duo-style)
  static const Color duoBlue = Color(0xFF1CB0F6);
  static const Color duoBlueDark = Color(0xFF1899D6);
  static const Color duoGreen = Color(0xFF78C800);
  static const Color duoGreenDark = Color(0xFF58A700);
  static const Color duoOrange = Color(0xFFFF9600);
  static const Color duoOrangeDark = Color(0xFFD37D00);
  static const Color duoRed = Color(0xFFFF4B4B);
  static const Color duoRedDark = Color(0xFFD33131);
  static const Color duoPurple = Color(0xFFCE82FF);
  static const Color duoPurpleDark = Color(0xFFAF67E9);
  static const Color duoYellow = Color(0xFFFFC800);
  static const Color duoYellowDark = Color(0xFFE5A100);

  // Pure Black & White
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color richBlack = Color(0xFF0D0D0D);
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2D2D2D);

  // ============== ACCENT COLORS ==============
  // Complementary accents for variety
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color accentYellow = Color(0xFFFFEA00);
  static const Color accentCoral = Color(0xFFFF6E6E);
  static const Color accentMint = Color(0xFF1DE9B6);
  static const Color accentCyan = Color(0xFF00E5FF);

  // ============== KID-FRIENDLY QUIZ COLORS ==============
  // Warm background
  static const Color quizBackground = Color(0xFFFFF8F0);
  static const Color quizBackgroundDark = Color(0xFF1A1510);

  // Answer card backgrounds (soft pastels)
  static const Color quizCardA = Color(0xFFFFF9E6); // Light yellow
  static const Color quizCardB = Color(0xFFFFECD6); // Light orange/peach
  static const Color quizCardC = Color(0xFFF0E6FF); // Light purple
  static const Color quizCardD = Color(0xFFE6F9E6); // Light green

  // Letter badge colors (vibrant)
  static const Color quizBadgeA = Color(0xFFF9C846); // Yellow
  static const Color quizBadgeB = Color(0xFFF97B4B); // Orange
  static const Color quizBadgeC = Color(0xFF9B72CF); // Purple
  static const Color quizBadgeD = Color(0xFF4CAF50); // Green

  // Feedback colors
  static const Color quizCorrect = Color(0xFF4CAF50);
  static const Color quizIncorrect = Color(0xFFE57373);

  // Next button gradient
  static const LinearGradient quizNextButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF8C5A), Color(0xFFFF6B4B)],
  );

  // ============== SEMANTIC COLORS ==============
  static const Color success = Color(0xFF00E676);
  static const Color successSoft = Color(0xFF1B5E20);
  static const Color error = Color(0xFFFF5252);
  static const Color errorSoft = Color(0xFF421C1C);
  static const Color warning = Color(0xFFFFD600);
  static const Color warningSoft = Color(0xFF4A4000);
  static const Color info = Color(0xFF448AFF);
  static const Color infoSoft = Color(0xFF1A237E);

  // ============== LIGHT MODE ==============
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightBorderSubtle = Color(0xFFF0F0F0);

  // ============== DARK MODE (Premium Black) ==============
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceElevated = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF3D3D3D);
  static const Color darkBorderSubtle = Color(0xFF252525);

  // ============== TEXT COLORS ==============
  // Light mode text
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF424242);
  static const Color textTertiaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // Dark mode text
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFE0E0E0);
  static const Color textTertiaryDark = Color(0xFF9E9E9E);
  static const Color textDisabledDark = Color(0xFF616161);

  // ============== PREMIUM GRADIENTS ==============

  // Hero gradient - Signature green (logo colors)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1EE088), Color(0xFF00C767)],
  );

  static const LinearGradient heroGradientAlt = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5DFFA8), Color(0xFF1EE088)],
  );

  // Premium logo-derived gradient (for hero sections)
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1EE088), // Logo primary
      Color(0xFF00C767), // Deeper
      Color(0xFF00A855), // Darkest
    ],
  );

  // Dark premium gradient
  static const LinearGradient darkPremiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
  );

  // Green glow gradient (updated with logo colors)
  static const LinearGradient greenGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1EE088), Color(0xFF00C767), Color(0xFF009650)],
  );

  // Premium card gradients (logo-derived)
  static const LinearGradient premiumGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1EE088), Color(0xFF00C767)],
  );

  static const LinearGradient premiumMint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
  );

  static const LinearGradient premiumPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
  );

  static const LinearGradient premiumPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4081), Color(0xFFF50057)],
  );

  static const LinearGradient premiumOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFAB40), Color(0xFFFF9100)],
  );

  static const LinearGradient premiumCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18FFFF), Color(0xFF00E5FF)],
  );

  static const LinearGradient premiumCoral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
  );

  // Mesh gradients for backgrounds
  static const LinearGradient meshLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF), Color(0xFFF0FFF4)],
  );

  static const LinearGradient meshDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF0D0D0D), Color(0xFF001A0D)],
  );

  // Dark mode card gradients
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
  );

  // Banner/Feature gradients
  static const LinearGradient skyBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF40C4FF), Color(0xFF00B0FF)],
  );

  static const LinearGradient peachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFAB91), Color(0xFFFF8A65)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
  );

  // Category gradients - Vibrant and distinct
  static const List<LinearGradient> categoryGradients = [
    premiumGreen,
    premiumPurple,
    premiumMint,
    premiumOrange,
    premiumPink,
    premiumCyan,
  ];

  // ============== MODERN EVOLUTION (BENTO & GLASS) ==============
  // Glass variants
  static Color glass(BuildContext context, {double opacity = 0.1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);
  }

  static Color glassBorderColor(BuildContext context, {double opacity = 0.1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);
  }

  // Bento card colors
  static const Color bento1 = Color(0xFF1EE088);
  static const Color bento2 = Color(0xFF7C4DFF);
  static const Color bento3 = Color(0xFFFF4081);
  static const Color bento4 = Color(0xFF1CB0F6);

  // Sophisticated Shadows
  static List<BoxShadow> bentoShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> fluidShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  // ============== SHADOWS ==============
  // Subtle - for base cards
  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // Soft - for elevated cards
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Medium - for floating elements
  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // Large - for modals and overlays
  static List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 50,
      offset: const Offset(0, 20),
      spreadRadius: -8,
    ),
  ];

  // Green glow shadows
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

  // Premium green button shadow
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // Neon glow effect
  static List<BoxShadow> neonGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.6),
      blurRadius: 30,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 60,
      spreadRadius: 10,
    ),
  ];

  // For backward compatibility
  static const Color primaryCyan = primary;
  static const Color primaryTeal = primaryDark;
  static const Color primaryDeep = richBlack;
  static const Color accentGold = accentYellow;
  static const Color accentPeach = Color(0xFFFFAB91);
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static LinearGradient primaryGradient = heroGradient;

  static List<BoxShadow> coloredShadow(Color color) => glowShadow(color);
}
