import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:flynse/features/transaction/add_edit_transaction_page.dart';
import 'package:flynse/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavingsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const SavingsList({super.key, required this.transactions});

  Future<void> _deleteSavingTransaction(BuildContext context, int id) async {
    await context.read<TransactionProvider>().deleteTransaction(id);
    await context.read<AppProvider>().refreshAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving transaction deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (transactions.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16),
          child: Text(
            'Recent Savings',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ..._buildTransactionList(context, transactions, theme),
      ],
    );
  }

  List<Widget> _buildTransactionList(BuildContext context,
      List<Map<String, dynamic>> transactions, ThemeData theme) {
    return List.generate(transactions.length, (index) {
      final transaction = transactions[index];
      final transactionDate = DateTime.parse(transaction['transaction_date']);
      final isUsedSavings = (transaction['amount'] as num) < 0;

      final bool showDateHeader = (index == 0) ||
          !isSameDay(transactionDate,
              DateTime.parse(transactions[index - 1]['transaction_date']));

      final transactionItem = _SavingsListItem(
        transaction: transaction,
        isUsedSavings: isUsedSavings,
        onTap: () {
          if (!isUsedSavings) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AddEditTransactionPage(transaction: transaction)));
          }
        },
      );

      final Widget dismissibleItem = Dismissible(
              key: ValueKey(transaction['id']),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: Text('Are you sure you want to delete the saving entry: "${transaction['description']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (direction) {
                _deleteSavingTransaction(context, transaction['id']);
              },
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: transactionItem,
            );

      if (showDateHeader) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 16.0, left: 8.0, bottom: 8.0),
              child: Text(
                formatDateHeader(transactionDate),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                ),
              ),
            ),
            dismissibleItem,
          ],
        );
      } else {
        return dismissibleItem;
      }
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.savings_outlined,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No savings yet.',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first saving transaction.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isUsedSavings;
  final VoidCallback onTap;

  const _SavingsListItem({
    required this.transaction,
    required this.isUsedSavings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUsedSavings ? theme.colorScheme.secondary : Colors.lightGreen.shade500;
    final iconData = isUsedSavings ? Icons.north_east_rounded : Icons.savings_outlined;
    final amount = (transaction['amount'] as num).abs();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  transaction['description'],
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${NumberFormat.decimalPattern().format(amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}