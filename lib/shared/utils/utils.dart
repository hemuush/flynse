import 'package:intl/intl.dart';

/// A collection of utility functions used across the application.
/// Creating this file helps avoid code duplication and improves maintainability.

/// Checks if two DateTime objects represent the same calendar day.
bool isSameDay(DateTime dateA, DateTime dateB) {
  return dateA.year == dateB.year &&
      dateA.month == dateB.month &&
      dateA.day == dateB.day;
}

/// Formats a DateTime object into a user-friendly string like "Today", "Yesterday", or "July 20, 2024".
String formatDateHeader(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateToCompare = DateTime(date.year, date.month, date.day);

  if (dateToCompare == today) {
    return 'Today';
  } else if (dateToCompare == yesterday) {
    return 'Yesterday';
  } else {
    return DateFormat.yMMMMd().format(date);
  }
}
