import 'package:flutter/material.dart';

/// Olitun App Colors - Premium Green/White/Black Design System
/// Derived from the Olitun logo: Vibrant Mint Green (#1EE088)
class AppColors {
  AppColors._();

  // ============== PRIMARY BRAND COLORS ==============
  static const Color primary = Color(0xFF1EE088);
  static const Color primaryLight = Color(0xFF5DFFA8);
  static const Color primaryDark = Color(0xFF00C767);

  // Playful Gamified Accents (Duo-style)
  static const Color duoBlue = Color(0xFF1CB0F6);
  static const Color duoBlueDark = Color(0xFF1899D6);
  static const Color duoGreen = Color(0xFF78C800);
  static const Color duoOrange = Color(0xFFFF9600);
  static const Color duoOrangeDark = Color(0xFFD37D00);
  static const Color duoPurple = Color(0xFFCE82FF);
  static const Color duoRed = Color(0xFFFF4B4B);
  static const Color duoRedDark = Color(0xFFD33131);
  static const Color duoYellow = Color(0xFFFFC800);
  static const Color duoYellowDark = Color(0xFFE5A100);

  // Avatar background colors
  static const List<List<Color>> avatarPalettes = [
    [Color(0xFF1EE088), Color(0xFF00C767)],
    [Color(0xFF1CB0F6), Color(0xFF1899D6)],
    [Color(0xFFFF9600), Color(0xFFD37D00)],
    [Color(0xFFCE82FF), Color(0xFFAF67E9)],
    [Color(0xFFFF4B4B), Color(0xFFD33131)],
    [Color(0xFFFFC800), Color(0xFFE5A100)],
    [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    [Color(0xFFFF4081), Color(0xFFF50057)],
  ];

  // Pure Black & White / Grays
  static const Color pureBlack = Color(0xFF000000);
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2D2D2D);

  // ============== ACCENT COLORS ==============
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentCoral = Color(0xFFFF6E6E);
  static const Color accentCyan = Color(0xFF00E5FF);

  // ============== KID-FRIENDLY QUIZ COLORS ==============
  static const Color quizBackground = Color(0xFFFFF8F0);
  static const Color quizCardA = Color(0xFFFFF9E6);
  static const Color quizCardB = Color(0xFFFFECD6);
  static const Color quizCardC = Color(0xFFF0E6FF);
  static const Color quizCardD = Color(0xFFE6F9E6);
  static const Color quizBadgeA = Color(0xFFF9C846);
  static const Color quizBadgeB = Color(0xFFF97B4B);
  static const Color quizBadgeC = Color(0xFF9B72CF);
  static const Color quizBadgeD = Color(0xFF4CAF50);

  // Feedback colors
  static const Color quizCorrect = Color(0xFF4CAF50);
  static const Color quizIncorrect = Color(0xFFE57373);
  static const Color quizDarkBackground = Color(0xFF0A0E14);
  static const Color quizDarkCard = Color(0xFF152232);
  static const Color quizDarkCardAlt = Color(0xFF0F1A24);
  static const Color quizDarkBubble = Color(0xFF1C2C3E);
  static const Color quizLightSuccessSurface = Color(0xFFF0FDF4);
  static const Color quizLightBubble = Color(0xFFF3F4F6);

  // Next button gradient
  static const LinearGradient quizNextButton = LinearGradient(
    colors: [Color(0xFFFF8C5A), Color(0xFFFF6B4B)],
  );

  // ============== SEMANTIC COLORS ==============
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD600);

  // ============== LIGHT MODE ==============
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // ============== DARK MODE (Premium Black) ==============
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceElevated = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF3D3D3D);

  // ============== TEXT COLORS ==============
  static const Color brandTextLight = Color(0xFF007A45);
  static const Color brandTextDark = Color(0xFF5DFFA8);

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

  static const List<LinearGradient> categoryGradients = [
    premiumGreen,
    premiumPurple,
    premiumMint,
    premiumOrange,
    premiumCoral,
    premiumCyan,
  ];

  // ============== MODERN EVOLUTION ==============
  static Color glass(BuildContext context, {double opacity = 0.1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);
  }

  static List<BoxShadow> fluidShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 50,
      offset: const Offset(0, 20),
      spreadRadius: -8,
    ),
  ];

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

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => glowShadow(color);
  static const Color primaryPurple = Color(0xFF7C4DFF);
}
