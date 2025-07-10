import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A redesigned widget to show the highest and lowest expenses for the
/// month in a single, unified, and visually appealing card.
class MonthlyHighlights extends StatelessWidget {
  const MonthlyHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    final highestExpense = provider.highestExpense;
    final lowestExpense = provider.lowestExpense;

    // Don't build the card if there's no data to show.
    if ((highestExpense == null || highestExpense['amount'] == 0.0) &&
        (lowestExpense == null || lowestExpense['amount'] == 0.0)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (highestExpense != null && highestExpense['amount'] > 0.0)
              _HighlightRow(
                title: 'Highest Expense',
                icon: Icons.trending_up_rounded,
                iconColor: theme.colorScheme.secondary,
                transaction: highestExpense,
              ),
            if (highestExpense != null &&
                highestExpense['amount'] > 0.0 &&
                lowestExpense != null &&
                lowestExpense['amount'] > 0.0)
              const Divider(height: 1, indent: 20, endIndent: 20),
            if (lowestExpense != null && lowestExpense['amount'] > 0.0)
              _HighlightRow(
                title: 'Lowest Expense',
                icon: Icons.trending_down_rounded,
                iconColor: theme.colorScheme.tertiary,
                transaction: lowestExpense,
              ),
          ],
        ),
      ),
    );
  }
}

/// A helper widget to build a single row within the highlights card.
class _HighlightRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Map<String, dynamic> transaction;

  const _HighlightRow({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final amount = transaction['amount'] as double? ?? 0.0;
    final description = transaction['description'] as String?;
    final category = transaction['category'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  description ?? category ?? '',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            nf.format(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}