import 'package:flutter/material.dart';

/// A class to centralize all application-wide constant values.
///
/// This helps in maintaining a consistent design and makes it easy to update
/// recurring values from a single location.
class AppConstants {
  // --- Private constructor to prevent instantiation ---
  AppConstants._();

  // --- App Info ---
  static const String kAppName = 'Flynse';

  // --- Padding & Spacing ---
  /// Standard padding for pages and main content areas (16.0).
  static const EdgeInsets kPagePadding = EdgeInsets.all(16.0);

  /// Padding for larger cards and sections (24.0).
  static const EdgeInsets kCardPaddingLarge = EdgeInsets.all(24.0);
  
  /// Padding for standard cards (20.0).
  static const EdgeInsets kCardPadding = EdgeInsets.all(20.0);

  /// Padding for smaller cards and list items (12.0).
  static const EdgeInsets kCardPaddingMedium = EdgeInsets.all(12.0);

  /// Standard horizontal padding.
  static const EdgeInsets kHorizontalPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
  
  /// Standard vertical padding.
  static const EdgeInsets kVerticalPadding =
      EdgeInsets.symmetric(vertical: 16.0);
      
  /// Standard spacing between elements (16.0).
  static const SizedBox kSpacing = SizedBox(height: 16, width: 16);
  
  /// Smaller spacing between elements (8.0).
  static const SizedBox kSmallSpacing = SizedBox(height: 8, width: 8);

  /// Larger spacing between elements (24.0).
  static const SizedBox kLargeSpacing = SizedBox(height: 24, width: 24);


  // --- Border Radius ---
  /// Standard border radius for input fields and smaller elements (12.0).
  static final BorderRadius kBorderRadius = BorderRadius.circular(12.0);

  /// Larger border radius for cards and sheets (16.0).
  static final BorderRadius kBorderRadiusLarge = BorderRadius.circular(16.0);
  
  /// Extra large border radius for prominent cards (20.0).
  static final BorderRadius kBorderRadiusXLarge = BorderRadius.circular(20.0);
  
  /// Extra extra large border radius for sheets and popups (24.0).
  static final BorderRadius kBorderRadiusXXLarge = BorderRadius.circular(24.0);
}