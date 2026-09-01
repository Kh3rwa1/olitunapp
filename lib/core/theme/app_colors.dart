import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = C(0xFF1EE088),
      primaryLight = C(0xFF5DFFA8),
      primaryDark = C(0xFF00C767),
      duoBlue = C(0xFF1CB0F6),
      duoBlueDark = C(0xFF1899D6),
      duoGreen = C(0xFF78C800),
      duoOrange = C(0xFFFF9600),
      duoOrangeDark = C(0xFFD37D00),
      duoPurple = C(0xFFCE82FF),
      duoRed = C(0xFFFF4B4B),
      duoRedDark = C(0xFFD33131),
      duoYellow = C(0xFFFFC800),
      duoYellowDark = C(0xFFE5A100),
      avatarPalettes = [
        [primary, primaryDark],
        [duoBlue, duoBlueDark],
        [duoOrange, duoOrangeDark],
        [duoPurple, C(0xFFAF67E9)],
        [duoRed, duoRedDark],
        [duoYellow, duoYellowDark],
        [accentCyan, C(0xFF00B8D4)],
        [accentPink, C(0xFFF50057)],
      ],
      pureBlack = Colors.black,
      softBlack = C(0xFF1A1A1A),
      charcoal = C(0xFF2D2D2D),
      accentPurple = C(0xFF7C4DFF),
      accentPink = C(0xFFFF4081),
      accentCoral = C(0xFFFF6E6E),
      accentCyan = C(0xFF00E5FF),
      quizBackground = C(0xFFFFF8F0),
      quizCardA = C(0xFFFFF9E6),
      quizCardB = C(0xFFFFECD6),
      quizCardC = C(0xFFF0E6FF),
      quizCardD = C(0xFFE6F9E6),
      quizBadgeA = C(0xFFF9C846),
      quizBadgeB = C(0xFFF97B4B),
      quizBadgeC = C(0xFF9B72CF),
      quizBadgeD = C(0xFF4CAF50),
      quizIncorrect = C(0xFFE57373),
      quizDarkBackground = C(0xFF0A0E14),
      quizDarkCard = C(0xFF152232),
      quizDarkCardAlt = C(0xFF0F1A24),
      quizDarkBubble = C(0xFF1C2C3E),
      quizLightSuccessSurface = C(0xFFF0FDF4),
      quizLightBubble = C(0xFFF3F4F6),
      quizNextButton = G(colors: [C(0xFFFF8C5A), C(0xFFFF6B4B)]),
      success = C(0xFF00E676),
      error = C(0xFFFF5252),
      warning = C(0xFFFFD600),
      lightBackground = C(0xFFF8F9FA),
      lightSurface = Colors.white,
      lightSurfaceVariant = C(0xFFF1F3F5),
      lightBorder = C(0xFFE0E0E0),
      darkBackground = Colors.black,
      darkSurface = C(0xFF121212),
      darkSurfaceElevated = C(0xFF1E1E1E),
      darkSurfaceVariant = C(0xFF2A2A2A),
      darkBorder = C(0xFF3D3D3D),
      textPrimaryLight = Colors.black,
      textSecondaryLight = C(0xFF424242),
      textTertiaryLight = C(0xFF757575),
      textDisabledLight = C(0xFFBDBDBD),
      textPrimaryDark = Colors.white,
      textTertiaryDark = C(0xFF9E9E9E),
      textDisabledDark = C(0xFF616161),
      heroGradient = Lg([primary, primaryDark]),
      heroGradientAlt = G(colors: [primaryLight, primary], begin: tc, end: bc),
      premiumGreen = heroGradient,
      premiumMint = Lg([c0, c1]),
      premiumPurple = Lg([accentPurple, c2]),
      premiumOrange = Lg([c3, c4]),
      premiumCyan = Lg([c5, accentCyan]),
      premiumCoral = Lg([c6, error]),
      skyBlueGradient = Lg([c7, c8]),
      peachGradient = Lg([c9, c10]),
      sunsetGradient = Lg([c11, c12]),
      mintGradient = Lg([c13, c0]),
      purpleGradient = Lg([c14, accentPurple]),
      primaryPurple = accentPurple;

  static const quizCorrect = quizBadgeD,
      brandTextLight = C(0xFF007A45),
      brandTextDark = primaryLight,
      textSecondaryDark = lightBorder,
      badgeLetters = C(0xFF9C27B0),
      badgeNumbers = C(0xFFFF9800),
      badgeWords = C(0xFF2196F3),
      badgeSentences = C(0xFF009688),
      badgeVideo = C(0xFFF44336),
      badgeAudio = primary,
      badgeQuiz = C(0xFFFFC107),
      badgeTracing = C(0xFF3F51B5),
      badgeTyping = C(0xFF00BCD4),
      badgeLesson = C(0xFF607D8B),
      // Quiz feedback semantic tokens
      quizFeedbackSuccessDarkBg = C(
        0xFF0F2E1E,
      ),
      quizFeedbackSuccessLightBg = C(0xFFE8FDF0),
      quizFeedbackErrorDarkBg = C(0xFF3B1E1E),
      quizFeedbackErrorLightBg = C(0xFFFDE8E8),
      quizFeedbackSuccessDarkBorder = C(0xFF1B5E20),
      quizFeedbackSuccessLightBorder = C(0xFFB9F6CA),
      quizFeedbackErrorDarkBorder = C(0xFF7F1D1D),
      quizFeedbackErrorLightBorder = C(0xFFFFCDD2),
      quizFeedbackSuccessDarkFg = C(0xFF5DFFA8),
      quizFeedbackSuccessLightFg = C(0xFF1B5E20),
      quizFeedbackErrorDarkFg = C(0xFFFF5252),
      quizFeedbackErrorLightFg = C(0xFFB71C1C),
      quizFeedbackSuccessDarkIcon = C(0xFF1EE088),
      quizFeedbackSuccessLightIcon = C(0xFF2E7D32),
      quizFeedbackErrorDarkIcon = C(0xFFFF5252),
      quizFeedbackErrorLightIcon = C(0xFFC62828),
      // Mistake review card tokens
      mistakeCardDarkTop = C(
        0xFF2C1B1B,
      ),
      mistakeCardDarkBottom = C(0xFF1F1212),
      mistakeCardLightTop = C(0xFFFFF5F5),
      mistakeCardLightBottom = C(0xFFFFF0F0),
      mistakeCardDarkBorder = C(0xFF4A2525),
      mistakeCardLightBorder = C(0xFFFCA5A5),
      mistakeBadgeDarkBg = C(0xFF4A2525),
      mistakeBadgeLightBg = C(0xFFFEE2E2),
      mistakeBadgeDarkFg = C(0xFFFCA5A5),
      // Ambient background & orb tokens
      ambientIndigoDark = C(
        0xFF0F172A,
      ),
      ambientDeepPurpleDark = C(0xFF1E1B4B),
      ambientLightBlueTop = C(0xFFF8FAFC),
      ambientLightBlueBottom = C(0xFFEFF6FF),
      ambientBlueOrb = C(0xFF3B82F6),
      ambientBlueOrbLight = C(0xFF60A5FA),
      ambientIndigoOrb = C(0xFF6366F1),
      ambientIndigoOrbLight = C(0xFF818CF8),
      ambientPurpleOrb = C(0xFF8B5CF6),
      ambientPurpleOrbLight = C(0xFFA78BFA),
      // Translator surface tokens
      translatorDarkBg = C(
        0xFF0A0E1A,
      ),
      translatorDarkMid = C(0xFF121A2B),
      translatorDarkLight = C(0xFF1E2A44),
      translatorLightBg = C(0xFFF5F7FA),
      translatorLightCardA = C(0xFFF3F8FF),
      translatorLightCardB = C(0xFFF8FAFF),
      translatorLightCardC = C(0xFFE8F0FF),
      xpNeutral = C(0xFF9E9E9E);

  static const categoryGradients = [
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

  static const fluidShadow = [
        S(color: C(0x261EE088), blurRadius: 40, offset: o12, spreadRadius: -8),
      ],
      softShadow = [S(color: C(0x14000000), blurRadius: 20, offset: o4)],
      largeShadow = [
        S(color: C(0x33000000), blurRadius: 50, offset: o20, spreadRadius: -8),
      ],
      buttonShadow = [
        S(color: C(0x661EE088), blurRadius: 20, offset: o8, spreadRadius: -4),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
    S(
      color: color.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: o8,
      spreadRadius: -4,
    ),
    S(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: o4),
  ];
}

const tl = Alignment.topLeft,
    br = Alignment.bottomRight,
    tc = Alignment.topCenter,
    bc = Alignment.bottomCenter;

const o4 = Offset(0, 4),
    o8 = Offset(0, 8),
    o12 = Offset(0, 12),
    o20 = Offset(0, 20);

const c0 = C(0xFF1DE9B6),
    c1 = C(0xFF00BFA5),
    c2 = C(0xFF651FFF),
    c3 = C(0xFFFFAB40),
    c4 = C(0xFFFF9100),
    c5 = C(0xFF18FFFF),
    c6 = C(0xFFFF8A80),
    c7 = C(0xFF40C4FF),
    c8 = C(0xFF00B0FF),
    c9 = C(0xFFFFAB91),
    c10 = C(0xFFFF8A65),
    c11 = C(0xFFFFD54F),
    c12 = C(0xFFFFB300),
    c13 = C(0xFF64FFDA),
    c14 = C(0xFFB388FF);

typedef G = LinearGradient;
typedef S = BoxShadow;
typedef C = Color;

class Lg extends G {
  const Lg(List<Color> c) : super(colors: c, begin: tl, end: br);
}
