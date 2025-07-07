import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyHighlights extends StatelessWidget {
  const MonthlyHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    // --- REFACTORED: Pass category data to the card ---
    final highlightCards = [
      _HighlightCard(
        title: 'Highest Expense',
        icon: Icons.trending_up_rounded,
        iconColor: theme.colorScheme.secondary,
        amount: provider.highestExpense?['amount'] ?? 0.0,
        description: provider.highestExpense?['description'],
        category: provider.highestExpense?['category'],
        subCategory: provider.highestExpense?['sub_category'],
      ),
      const SizedBox(width: 16),
      _HighlightCard(
        title: 'Lowest Expense',
        icon: Icons.trending_down_rounded,
        iconColor: theme.colorScheme.primary,
        amount: provider.lowestExpense?['amount'] ?? 0.0,
        description: provider.lowestExpense?['description'],
        category: provider.lowestExpense?['category'],
        subCategory: provider.lowestExpense?['sub_category'],
      ),
    ];

    // Only show the highlights if there is data to display
    if ((provider.highestExpense == null ||
            provider.highestExpense!['amount'] == 0.0) &&
        (provider.lowestExpense == null ||
            provider.lowestExpense!['amount'] == 0.0)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150, // Set a fixed height for the horizontal list
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: highlightCards,
      ),
    );
  }
}

// --- REFACTORED: Updated card to show category info ---
class _HighlightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double amount;
  final String? description;
  final String? category;
  final String? subCategory;

  const _HighlightCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.amount,
    this.description,
    this.category,
    this.subCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    // Build the category string
    String categoryText = category ?? '';
    if (subCategory != null && subCategory!.isNotEmpty) {
      categoryText += ' > $subCategory';
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // Card width
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // PERMANENT FIX: Use a SingleChildScrollView to prevent overflow.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  nf.format(amount),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Show the description or the category as a fallback
                if (description != null && description!.isNotEmpty)
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (categoryText.isNotEmpty)
                  Text(
                    categoryText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
