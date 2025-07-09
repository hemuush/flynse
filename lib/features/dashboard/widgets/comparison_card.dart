import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A new card for the dashboard that compares the current month's spending
/// to the previous month, providing a quick, insightful metric.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();

    final currentExpense = provider.monthlyTotals['Expense'] ?? 0.0;
    final previousExpense = provider.previousMonthExpense;
    final difference = previousExpense - currentExpense;

    // Don't show the card if there's no data for comparison
    if (currentExpense == 0.0 || previousExpense == 0.0) {
      return const SizedBox.shrink();
    }

    final bool isSpendingLess = difference > 0;
    final nf = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedDiff = nf.format(difference.abs());

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (isSpendingLess) {
      title = 'Spending less!';
      subtitle = 'You spent $formattedDiff less than last month.';
      icon = Icons.trending_down_rounded;
      iconColor = theme.colorScheme.tertiary;
    } else {
      title = 'Spending more';
      subtitle = 'You spent $formattedDiff more than last month.';
      icon = Icons.trending_up_rounded;
      iconColor = theme.colorScheme.secondary;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
