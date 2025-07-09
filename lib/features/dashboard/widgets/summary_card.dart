import 'package:flutter/material.dart';

/// A redesigned, visually appealing card for displaying summary information
/// on the dashboard.
///
/// This card uses a clear visual hierarchy to present data, with a prominent
/// amount and a clean, modern aesthetic. The background color is a light
/// tint of the main icon color, creating a cohesive and attractive look.
class SummaryCard extends StatelessWidget {
  /// The main title of the card (e.g., "Total Savings").
  final String title;

  /// The primary value to display, typically a formatted currency amount.
  final String amount;

  /// The icon to display, representing the card's category.
  final IconData icon;

  /// The primary color used for the icon and the card's background tint.
  final Color color;

  /// The callback function to execute when the card is tapped.
  final VoidCallback onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      // No shadow for a flatter, modern look.
      elevation: 0,
      // The card's shape with rounded corners.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      // Use a light tint of the primary color for the background.
      color: color.withAlpha(26),
      // Ensures the InkWell splash effect is clipped to the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Top Section: Icon and Title ---
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // The icon, styled with the provided color.
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  // The title text, which can expand and wrap if needed.
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Bottom Section: Amount ---
              // The main amount, displayed prominently.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
