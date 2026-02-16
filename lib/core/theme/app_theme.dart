import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ============== LIGHT THEME ==============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.duoBlue,
        secondaryContainer: AppColors.duoBlueDark,
        tertiary: AppColors.duoYellow,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Poppins',

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Elevated Button Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textTertiaryLight,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: _textTheme(
        AppColors.textPrimaryLight,
        AppColors.textSecondaryLight,
      ),
    );
  }

  // ============== DARK THEME ==============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.duoBlue,
        secondaryContainer: AppColors.duoBlueDark,
        tertiary: AppColors.duoYellow,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Poppins',

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Elevated Button Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black, // High contrast on Mint Green
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textTertiaryDark,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryCyan,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: _textTheme(
        AppColors.textPrimaryDark,
        AppColors.textSecondaryDark,
      ),
    );
  }

  // ============== TEXT THEME ==============
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primary,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
