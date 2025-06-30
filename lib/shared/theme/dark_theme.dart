import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/shared/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class to centralize all application theme-related configurations for dark mode.
class DarkTheme {
  // --- Private constructor to prevent instantiation ---
  DarkTheme._();

  // --- Dark Theme Color Scheme ---
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4A90E2), // A lighter blue for dark mode seed
    brightness: Brightness.dark,
    primary: const Color(0xFF58A6FF), // A clear, accessible blue for dark theme
    secondary: const Color(0xFFFF8A8A), // Reddish/coral for FAB and accents
    tertiary: Colors.green.shade400,
    surface: const Color(0xFF121212),
    surfaceContainer: const Color(0xFF1E1E1E),
    surfaceContainerHighest: const Color(0xFF2C2C2E),
    onPrimary: Colors.black, // Text on primary color should be dark for contrast
    outline: Colors.grey.shade700,
  );

  /// Builds the theme data based on the dark color scheme.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: colorScheme.brightness).textTheme,
      ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Light icons for dark theme
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: baseTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.kBorderRadiusLarge,
        ),
      ),
      // --- UI ENHANCEMENT: Input Field Theme ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: AppConstants.kBorderRadius,
          borderSide: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.kBorderRadius,
          borderSide: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConstants.kBorderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      // --- UI ENHANCEMENT: Button Themes ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppConstants.kBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: AppConstants.kBorderRadius),
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
       textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: AppConstants.kBorderRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // --- UI ENHANCEMENT: Chip Theme ---
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: AppConstants.kBorderRadiusXLarge),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        secondaryLabelStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onPrimary),
      ),
    );
  }

  /// Provides the ThemeData for the dark mode.
  static final ThemeData theme = _buildTheme(_darkColorScheme);
}
