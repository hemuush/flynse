import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/transaction/add_edit_transaction_page.dart';
import 'package:flynse/features/transaction/transaction_list_page.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:flynse/shared/widgets/transaction_list_item.dart';
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

    void showLockedDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Action Locked'),
          content: const Text(
              'This transaction is linked to a Debt, Saving, or a Friend and must be managed from the corresponding page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionListPage()),
                );
              },
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
            final type = transaction['type'] as String?;
            final category = transaction['category'] as String?;

            final isLocked = type == 'Saving' ||
                category == 'Loan' ||
                category == 'Debt Repayment' ||
                category == 'Savings Withdrawal' ||
                category == 'Friends' ||
                category == 'Friend Repayment';

            return TransactionListItem(
              transaction: transaction,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) {
                  showLockedDialog();
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditTransactionPage(
                      transaction: transaction,
                    ),
                  ));
                }
              },
            );
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
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
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
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.addEditTransactionPage,
                    arguments: AddEditTransactionPageArgs(),
                  );
                },
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
