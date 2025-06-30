import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/shared/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralizes all configurations for the application's light theme.
class LightTheme {
  // --- Private constructor to prevent instantiation ---
  LightTheme._();

  // --- MODIFIED: Light Theme Color Scheme ---
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF007AFF), // A bright, modern blue
    brightness: Brightness.light,
    primary: const Color(0xFF007AFF),
    secondary: const Color(0xFFFF6B6B), // A vibrant red for contrast
    tertiary: const Color(0xFF34C759), // A clear green for success states
    surface: Colors.white, // The main background is now pure white.
    surfaceContainer: const Color(0xFFF2F2F7),   // Cards are a light grey.
    surfaceContainerHighest: const Color(0xFFE5E5EA), // A light grey for containers
    onPrimary: Colors.white,
    outline: Colors.grey.shade300, // Lighter outline for light theme
  );

  /// Builds the theme data based on the light color scheme.
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark, // For Android
          statusBarBrightness: Brightness.light, // For iOS
        ),
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
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.kBorderRadius,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
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
          elevation: 0,
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

  /// Provides the ThemeData for the light mode.
  static final ThemeData theme = _buildTheme(_lightColorScheme);
}