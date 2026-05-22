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
      textSecondaryDark = lightBorder;

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
      softShadow = [
        S(color: C(0x14000000), blurRadius: 20, offset: o4),
      ],
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
