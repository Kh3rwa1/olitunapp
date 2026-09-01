import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Inter';
  static const _fontFallback = ['OlChiki'];

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    },
  );

  // ============== LIGHT THEME ==============
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.brandBlue,
        secondaryContainer: AppColors.brandBlueDark,
        tertiary: AppColors.accentGold,
        error: AppColors.error,
        onSecondary: Colors.white,
      ),
      scaffoldBg: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      surfaceVariant: AppColors.lightSurfaceVariant,
      border: AppColors.lightBorder,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textTertiary: AppColors.textTertiaryLight,
      overlayStyle: SystemUiOverlayStyle.dark,
      elevatedButtonFg: const Color(0xFF00391C), // WCAG AA: 7.2:1 on #1EE088
      snackBarBg: AppColors.charcoal,
      disabledText: AppColors.textDisabledLight,
    );
  }

  // ============== DARK THEME ==============
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.brandBlue,
        secondaryContainer: AppColors.brandBlueDark,
        tertiary: AppColors.accentGold,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBg: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      surfaceVariant: AppColors.darkSurfaceVariant,
      border: AppColors.darkBorder,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textTertiary: AppColors.textTertiaryDark,
      overlayStyle: SystemUiOverlayStyle.light,
      elevatedButtonFg: Colors.black, // High contrast on Mint Green
      snackBarBg: AppColors.softBlack,
      disabledText: AppColors.textDisabledDark,
    );
  }

  // ============== SHARED THEME BUILDER ==============
  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required SystemUiOverlayStyle overlayStyle,
    required Color elevatedButtonFg,
    required Color snackBarBg,
    required Color disabledText,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      pageTransitionsTheme: _pageTransitions,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: elevatedButtonFg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontFamilyFallback: _fontFallback,
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
            fontFamily: _fontFamily,
            fontFamilyFallback: _fontFallback,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontFamilyFallback: _fontFallback,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: brightness == Brightness.light
              ? Colors.white
              : Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontFamilyFallback: _fontFallback,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
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
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          color: textTertiary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
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
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      // Standardized accessible visual components (M3 Specs)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBarBg,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        disabledColor: disabledText,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        secondarySelectedColor: AppColors.primary.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Text Theme
      textTheme: _textTheme(textPrimary, textSecondary),
    );
  }

  // ============== TEXT THEME ==============
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
