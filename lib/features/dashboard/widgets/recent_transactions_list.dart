import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A widget that displays a list of the most recent transactions
/// for the currently selected period on the dashboard.
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();
    final transactions = provider.recentTransactions;

    if (transactions.isEmpty) {
      // Return an empty state if there are no transactions.
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Activity",
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.read<AppProvider>().navigateToTab(3), // Navigate to history tab
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // --- Transaction List ---
        ListView.separated(
          itemCount: transactions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _TransactionListItem(transaction: transaction);
          },
        ),
      ],
    );
  }

  /// Builds the view shown when there are no recent transactions.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "No transactions this month",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the '+' button to add your first transaction.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<AppProvider>().navigateToTab(2), // FAB index
                icon: const Icon(Icons.add_rounded),
                label: const Text("Add Transaction"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// A styled list item for displaying a single transaction.
/// This is a simplified version of the one in `transaction_list_page.dart`
/// for consistency in the UI.
class _TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionListItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = transaction['type'] as String? ?? '';
    final color = _getColorForType(context, type);
    final iconData = _getIconForType(type);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // --- Icon ---
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            // --- Title and Subtitle ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'],
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (transaction['category'] != null)
                    Text(
                      transaction['category'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // --- Amount ---
            Text(
              '₹${NumberFormat.decimalPattern('en_IN').format(transaction['amount'])}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to determine the icon and color based on transaction type.
  IconData _getIconForType(String type) {
    switch (type) {
      case 'Income':
        return Icons.arrow_downward_rounded;
      case 'Saving':
        return Icons.savings_rounded;
      case 'Expense':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getColorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    switch (type) {
      case 'Income':
        return theme.colorScheme.tertiary;
      case 'Saving':
        return Colors.lightGreen.shade500;
      case 'Expense':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
