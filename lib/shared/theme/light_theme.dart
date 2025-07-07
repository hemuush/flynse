import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/shared/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralizes all configurations for the application's light theme.
class LightTheme {
  // --- Private constructor to prevent instantiation ---
  LightTheme._();

  // MODIFICATION: This is now a static method that builds a theme from a seed color.
  static ThemeData buildTheme(Color? seedColor) {
    // Use the provided seed color, or a default bright blue if none is provided.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? const Color(0xFF007AFF),
      brightness: Brightness.light,
      primary: seedColor ?? const Color(0xFF007AFF),
      secondary: const Color(0xFFFF6B6B),
      tertiary: const Color(0xFF34C759),
      surface: Colors.white,
      surfaceContainer: const Color(0xFFF2F2F7),
      surfaceContainerHighest: const Color(0xFFE5E5EA),
      onPrimary: Colors.white,
      outline: Colors.grey.shade300,
    );

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
}
