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

  // --- Border Radius ---
  /// Standard border radius for input fields and smaller elements (12.0).
  static final BorderRadius kBorderRadius = BorderRadius.circular(12.0);

  /// Larger border radius for cards and sheets (16.0).
  static final BorderRadius kBorderRadiusLarge = BorderRadius.circular(16.0);
  
  /// Extra large border radius for prominent cards (20.0).
  static final BorderRadius kBorderRadiusXLarge = BorderRadius.circular(20.0);
  
  // --- FIX: Centralized Special Category Names ---
  // These constants prevent "magic string" errors and make the code safer.
  static const String kCatDebtRepayment = 'Debt Repayment';
  static const String kCatLoan = 'Loan';
  static const String kCatSavingsWithdrawal = 'Savings Withdrawal';
  static const String kCatBank = 'Bank';
  static const String kCatShopping = 'Shopping';
  static const String kCatOthers = 'Others';
  static const String kCatFriends = 'Friends';
  static const String kCatFriendRepayment = 'Friend Repayment';
  static const String kCatFromSavings = 'From Savings';
}
