import 'package:flutter/material.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/features/debt/ui/pages/repayment_history_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClosedLoansPage extends StatelessWidget {
  final bool? isUserDebtorFilter;

  const ClosedLoansPage({super.key, this.isUserDebtorFilter});

  @override
  Widget build(BuildContext context) {
    // Determine the title based on the filter
    String title = 'All Closed Loans & Debts';
    if (isUserDebtorFilter == true) {
      title = 'Your Closed Debts';
    } else if (isUserDebtorFilter == false) {
      title = 'Closed Loans to Others';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final completedUserDebts = provider.completedUserDebts;
          final completedFriendLoans = provider.completedFriendLoans;

          // Apply filtering logic
          final bool showUserDebts =
              isUserDebtorFilter == null || isUserDebtorFilter == true;
          final bool showFriendLoans =
              isUserDebtorFilter == null || isUserDebtorFilter == false;

          final bool noData = (!showUserDebts || completedUserDebts.isEmpty) &&
              (!showFriendLoans || completedFriendLoans.isEmpty);

          if (noData) {
            return const Center(
              child: Text('No closed items to display in this category.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            children: [
              if (showUserDebts && completedUserDebts.isNotEmpty) ...[
                _buildListHeader('Your Completed Debts', Theme.of(context)),
                ...completedUserDebts
                    .map((debt) => _buildDebtCard(context, debt)),
              ],
              if (showUserDebts &&
                  showFriendLoans &&
                  completedUserDebts.isNotEmpty &&
                  completedFriendLoans.isNotEmpty)
                const SizedBox(height: 24),
              if (showFriendLoans && completedFriendLoans.isNotEmpty) ...[
                _buildListHeader('Completed Loans to Others', Theme.of(context)),
                ...completedFriendLoans
                    .map((debt) => _buildDebtCard(context, debt)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildListHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Map<String, dynamic> debt) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final principalAmount =
        debt['principal_amount'] as double? ?? debt['total_amount'];
    final totalPaid = debt['amount_paid'] as double;
    final creationDate = DateTime.parse(debt['creation_date'] as String);

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
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(debt['name']),
        trailing: Icon(Icons.check_circle, color: Colors.green.shade400),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildDetailRow(
                    theme, "Principal Amount", nf.format(principalAmount)),
                _buildDetailRow(
                    theme, "Total Amount Paid", nf.format(totalPaid)),
                _buildDetailRow(theme, "Date of Creation",
                    DateFormat.yMMMd().format(creationDate)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text("View Repayment History"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RepaymentHistoryPage(debt: debt),
                      ));
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
