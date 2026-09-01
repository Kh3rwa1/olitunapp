import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Signature Olitun Brand Green
  static const Color primary = Color(0xFF1EE088);
  static const Color primaryLight = Color(0xFF5DFFA8);
  static const Color primaryDark = Color(0xFF00C767);

  // Santali Cultural Palette
  // Authentic Sohrai/Khovar earth pigments, sacred Sal groves, and twilight night sky
  static const Color santaliTerracotta = Color(0xFF8B3A3A);
  static const Color santaliTerracottaDark = Color(0xFF6B2A2A);
  static const Color santaliTerracottaLight = Color(0xFFB84A39);
  static const Color santaliOchre = Color(0xFFD99B26);
  static const Color santaliOchreDark = Color(0xFFB45309);
  static const Color santaliOchreLight = Color(0xFFE5A93C);
  static const Color santaliSalGreen = Color(0xFF1B4D3E);
  static const Color santaliSalGreenDark = Color(0xFF12352A);
  static const Color santaliSalGreenLight = Color(0xFF237A4B);
  static const Color santaliNightSky = Color(0xFF1E2A44);
  static const Color santaliNightSkyDark = Color(0xFF121A2B);
  static const Color santaliNightSkyLight = Color(0xFF2C3E6B);
  static const Color santaliEarthBlack = Color(0xFF181E24);
  static const Color santaliClayWhite = Color(0xFFFBF9F5);

  // Semantic Accents
  static const Color brandBlue = Color(0xFF1CB0F6);
  static const Color brandBlueDark = Color(0xFF1899D6);
  static const Color accentForest = santaliSalGreenLight;
  static const Color accentForestDark = santaliSalGreen;
  static const Color accentOchre = santaliOchre;
  static const Color accentOchreDark = santaliOchreDark;
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleDark = Color(0xFF7C3AED);
  static const Color accentTerracotta = santaliTerracotta;
  static const Color accentTerracottaDark = santaliTerracottaDark;
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldDark = santaliOchreDark;
  static const Color accentCoral = Color(0xFFFF6E6E);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPink = Color(0xFFFF4081);

  // Deprecated aliases for backwards compatibility
  @Deprecated('Use brandBlue instead')
  static const Color duoBlue = brandBlue;
  @Deprecated('Use brandBlueDark instead')
  static const Color duoBlueDark = brandBlueDark;
  @Deprecated('Use accentForest instead')
  static const Color duoGreen = accentForest;
  @Deprecated('Use accentOchre instead')
  static const Color duoOrange = accentOchre;
  @Deprecated('Use accentOchreDark instead')
  static const Color duoOrangeDark = accentOchreDark;
  @Deprecated('Use accentPurple instead')
  static const Color duoPurple = accentPurple;
  @Deprecated('Use accentTerracotta instead')
  static const Color duoRed = accentTerracotta;
  @Deprecated('Use accentTerracottaDark instead')
  static const Color duoRedDark = accentTerracottaDark;
  @Deprecated('Use accentGold instead')
  static const Color duoYellow = accentGold;
  @Deprecated('Use accentGoldDark instead')
  static const Color duoYellowDark = accentGoldDark;

  // Avatar Gradient Palettes
  static const List<List<Color>> avatarPalettes = [
    [primary, primaryDark],
    [santaliTerracotta, santaliTerracottaDark],
    [santaliOchre, santaliOchreDark],
    [santaliSalGreenLight, santaliSalGreen],
    [brandBlue, brandBlueDark],
    [accentPurple, accentPurpleDark],
    [accentCyan, Color(0xFF00B8D4)],
    [accentPink, Color(0xFFF50057)],
  ];

  // Neutrals & Surfaces
  static const Color pureBlack = Colors.black;
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color darkBackground = Colors.black;
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceElevated = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF3D3D3D);

  // Text Colors
  static const Color textPrimaryLight = Colors.black;
  static const Color textSecondaryLight = Color(0xFF424242);
  static const Color textTertiaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = lightBorder;
  static const Color textTertiaryDark = Color(0xFF9E9E9E);
  static const Color textDisabledDark = Color(0xFF616161);

  // Status & Feedback Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD600);
  static const Color brandTextLight = Color(0xFF007A45);
  static const Color brandTextDark = primaryLight;

  // Quiz Surfaces & Elements
  static const Color quizBackground = Color(0xFFFFF8F0);
  static const Color quizCardA = Color(0xFFFFF9E6);
  static const Color quizCardB = Color(0xFFFFECD6);
  static const Color quizCardC = Color(0xFFF0E6FF);
  static const Color quizCardD = Color(0xFFE6F9E6);
  static const Color quizBadgeA = Color(0xFFF9C846);
  static const Color quizBadgeB = Color(0xFFF97B4B);
  static const Color quizBadgeC = Color(0xFF9B72CF);
  static const Color quizBadgeD = Color(0xFF4CAF50);
  static const Color quizCorrect = quizBadgeD;
  static const Color quizIncorrect = Color(0xFFE57373);
  static const Color quizDarkBackground = Color(0xFF0A0E14);
  static const Color quizDarkCard = Color(0xFF152232);
  static const Color quizDarkCardAlt = Color(0xFF0F1A24);
  static const Color quizDarkBubble = Color(0xFF1C2C3E);
  static const Color quizLightSuccessSurface = Color(0xFFF0FDF4);
  static const Color quizLightBubble = Color(0xFFF3F4F6);
  static const LinearGradient quizNextButton = LinearGradient(
    colors: [Color(0xFFFF8C5A), Color(0xFFFF6B4B)],
  );

  // Badge Colors
  static const Color badgeLetters = Color(0xFF9C27B0);
  static const Color badgeNumbers = Color(0xFFFF9800);
  static const Color badgeWords = Color(0xFF2196F3);
  static const Color badgeSentences = Color(0xFF009688);
  static const Color badgeVideo = Color(0xFFF44336);
  static const Color badgeAudio = primary;
  static const Color badgeQuiz = Color(0xFFFFC107);
  static const Color badgeTracing = Color(0xFF3F51B5);
  static const Color badgeTyping = Color(0xFF00BCD4);
  static const Color badgeLesson = Color(0xFF607D8B);

  // Quiz Feedback Semantic Tokens
  static const Color quizFeedbackSuccessDarkBg = Color(0xFF0F2E1E);
  static const Color quizFeedbackSuccessLightBg = Color(0xFFE8FDF0);
  static const Color quizFeedbackErrorDarkBg = Color(0xFF3B1E1E);
  static const Color quizFeedbackErrorLightBg = Color(0xFFFDE8E8);
  static const Color quizFeedbackSuccessDarkBorder = Color(0xFF1B5E20);
  static const Color quizFeedbackSuccessLightBorder = Color(0xFFB9F6CA);
  static const Color quizFeedbackErrorDarkBorder = Color(0xFF7F1D1D);
  static const Color quizFeedbackErrorLightBorder = Color(0xFFFFCDD2);
  static const Color quizFeedbackSuccessDarkFg = Color(0xFF5DFFA8);
  static const Color quizFeedbackSuccessLightFg = Color(0xFF1B5E20);
  static const Color quizFeedbackErrorDarkFg = Color(0xFFFF5252);
  static const Color quizFeedbackErrorLightFg = Color(0xFFB71C1C);
  static const Color quizFeedbackSuccessDarkIcon = Color(0xFF1EE088);
  static const Color quizFeedbackSuccessLightIcon = Color(0xFF2E7D32);
  static const Color quizFeedbackErrorDarkIcon = Color(0xFFFF5252);
  static const Color quizFeedbackErrorLightIcon = Color(0xFFC62828);

  // Mistake Review Card Tokens
  static const Color mistakeCardDarkTop = Color(0xFF2C1B1B);
  static const Color mistakeCardDarkBottom = Color(0xFF1F1212);
  static const Color mistakeCardLightTop = Color(0xFFFFF5F5);
  static const Color mistakeCardLightBottom = Color(0xFFFFF0F0);
  static const Color mistakeCardDarkBorder = Color(0xFF4A2525);
  static const Color mistakeCardLightBorder = Color(0xFFFCA5A5);
  static const Color mistakeBadgeDarkBg = Color(0xFF4A2525);
  static const Color mistakeBadgeLightBg = Color(0xFFFEE2E2);
  static const Color mistakeBadgeDarkFg = Color(0xFFFCA5A5);

  // Ambient Background & Orb Tokens
  static const Color ambientIndigoDark = Color(0xFF0F172A);
  static const Color ambientDeepPurpleDark = Color(0xFF1E1B4B);
  static const Color ambientLightBlueTop = Color(0xFFF8FAFC);
  static const Color ambientLightBlueBottom = Color(0xFFEFF6FF);
  static const Color ambientBlueOrb = Color(0xFF3B82F6);
  static const Color ambientBlueOrbLight = Color(0xFF60A5FA);
  static const Color ambientIndigoOrb = Color(0xFF6366F1);
  static const Color ambientIndigoOrbLight = Color(0xFF818CF8);
  static const Color ambientPurpleOrb = Color(0xFF8B5CF6);
  static const Color ambientPurpleOrbLight = Color(0xFFA78BFA);

  // AI Translator Surface Tokens
  static const Color translatorDarkBg = Color(0xFF0A0E14);
  static const Color translatorDarkMid = Color(0xFF121A2B);
  static const Color translatorDarkLight = Color(0xFF1E2A44);
  static const Color translatorLightBg = Color(0xFFF5F7FA);
  static const Color translatorLightCardA = Color(0xFFF3F8FF);
  static const Color translatorLightCardB = Color(0xFFF8FAFF);
  static const Color translatorLightCardC = Color(0xFFE8F0FF);
  static const Color xpNeutral = Color(0xFF9E9E9E);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradientAlt = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient premiumGreen = heroGradient;
  static const LinearGradient premiumMint = LinearGradient(
    colors: [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient premiumPurple = LinearGradient(
    colors: [accentPurple, Color(0xFF651FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient premiumOrange = LinearGradient(
    colors: [Color(0xFFFFAB40), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient premiumCyan = LinearGradient(
    colors: [Color(0xFF18FFFF), accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient premiumCoral = LinearGradient(
    colors: [Color(0xFFFF8A80), error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient skyBlueGradient = LinearGradient(
    colors: [Color(0xFF40C4FF), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient peachGradient = LinearGradient(
    colors: [Color(0xFFFFAB91), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF64FFDA), Color(0xFF1DE9B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFB388FF), accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color primaryPurple = accentPurple;

  static const List<LinearGradient> categoryGradients = [
    premiumGreen,
    premiumPurple,
    premiumMint,
    premiumOrange,
    premiumCoral,
    premiumCyan,
  ];

  static Color glass(BuildContext c, {double opacity = 0.1}) =>
      (Theme.of(c).brightness == Brightness.dark ? Colors.white : Colors.black)
          .withValues(alpha: opacity);

  static const List<BoxShadow> fluidShadow = [
    BoxShadow(
      color: Color(0x261EE088),
      blurRadius: 40,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 50,
      offset: Offset(0, 20),
      spreadRadius: -8,
    ),
  ];
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x661EE088),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
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
}
