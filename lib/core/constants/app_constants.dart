/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Olitun';
  static const String appTagline = 'Learn Ol Chiki, Your Way';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Border Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Icon Sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Card Sizes
  static const double cardHeightSmall = 100.0;
  static const double cardHeightMedium = 140.0;
  static const double cardHeightLarge = 180.0;

  // Avatar Sizes
  static const double avatarSmall = 40.0;
  static const double avatarMedium = 56.0;
  static const double avatarLarge = 80.0;
  static const double avatarXLarge = 120.0;

  // Progress Ring Sizes
  static const double progressRingSmall = 48.0;
  static const double progressRingMedium = 64.0;
  static const double progressRingLarge = 80.0;

  // Max Widths
  static const double maxContentWidth = 600.0;
  static const double maxCardWidth = 400.0;

  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefScriptMode = 'script_mode';
  static const String prefSoundEnabled = 'sound_enabled';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefUserName = 'user_name';
  static const String prefUserLevel = 'user_level';
  static const String prefOnboardingComplete = 'onboarding_complete';

  // Firebase Collections
  static const String colCategories = 'categories';
  static const String colFeaturedBanners = 'featuredBanners';
  static const String colLetters = 'letters';
  static const String colLessons = 'lessons';
  static const String colQuizzes = 'quizzes';
  static const String colUsers = 'users';
  static const String colProgress = 'progress';
  static const String colStickers = 'stickers';
  static const String colAppStrings = 'appStrings';

  // Firebase Storage Paths
  static const String storageCategoryIcons = 'images/categories';
  static const String storageBannerImages = 'images/banners';
  static const String storageLetterImages = 'images/letters';
  static const String storageStickers = 'images/stickers';
  static const String storageLetterAudio = 'audio/letters';
  static const String storageLessonAudio = 'audio/lessons';

  // Script Modes
  static const String scriptOlChiki = 'olchiki';
  static const String scriptLatin = 'latin';
  static const String scriptBoth = 'both';

  // User Levels
  static const String levelBeginner = 'beginner';
  static const String levelIntermediate = 'intermediate';
  static const String levelAdvanced = 'advanced';

  // Theme Modes
  static const String themeSystem = 'system';
  static const String themeLight = 'light';
  static const String themeDark = 'dark';

  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // Gradient Presets
  static const String gradientSkyBlue = 'skyBlue';
  static const String gradientPeach = 'peach';
  static const String gradientSunset = 'sunset';
  static const String gradientCoral = 'coral';
  static const String gradientMint = 'mint';
  static const String gradientPurple = 'purple';
}
