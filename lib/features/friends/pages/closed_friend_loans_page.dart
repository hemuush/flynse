import 'package:flutter/material.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/settings/friend_history_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// This page displays all closed loans and debts with friends.
class ClosedFriendLoansPage extends StatelessWidget {
  const ClosedFriendLoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closed History with Friends'),
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final completedFriendLoans = friendProvider.completedFriendLoans;

          if (completedFriendLoans.isEmpty) {
            return const Center(
              child: Text('No closed items to display.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            children: [
              _buildListHeader('Completed Loans & Debts', Theme.of(context)),
              ...completedFriendLoans
                  .map((debt) => _buildDebtCard(context, debt)),
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
                    label: const Text("View Full History"),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => FriendHistoryPage(
                          friendId: debt['friend_id'],
                          friendName: debt['name'],
                        ),
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
