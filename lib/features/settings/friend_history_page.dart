import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/friend_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:flynse/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FriendHistoryPage extends StatefulWidget {
  final int friendId;
  final String friendName;

  const FriendHistoryPage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendHistoryPage> createState() => _FriendHistoryPageState();
}

class _FriendHistoryPageState extends State<FriendHistoryPage> {
  final FriendRepository _friendRepo = FriendRepository();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _friendRepo.getFriendTransactionHistory(widget.friendId);
    });
  }

  Future<void> _deleteTransaction(int transactionId) async {
    await context.read<TransactionProvider>().deleteTransaction(transactionId);
    await context.read<AppProvider>().refreshAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
      _loadHistory(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('History with ${widget.friendName}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No transaction history found with this friend.'),
            );
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final date = DateTime.parse(transaction['transaction_date']);
              final amount = transaction['amount'] as double;
              final type = transaction['type'] as String;
              final description = transaction['description'] as String;
              final isExpense = type == 'Expense'; // Money you gave

              final bool showDateHeader = (index == 0) ||
                  !isSameDay(
                      date,
                      DateTime.parse(
                          transactions[index - 1]['transaction_date']));

              final transactionCard = Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(
                    color:
                        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isExpense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: isExpense ? Colors.redAccent : Colors.green,
                  ),
                  title: Text(description),
                  subtitle: Text(isExpense ? "You paid" : "You received"),
                  trailing: Text(
                    '₹${NumberFormat.decimalPattern().format(amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );

              final item = Dismissible(
                key: ValueKey(transaction['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteTransaction(transaction['id']);
                },
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete this transaction: "$description"? This will affect the debt balance with ${widget.friendName}.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: transactionCard,
              );

              if (showDateHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, left: 8.0, bottom: 4.0),
                      child: Text(
                        formatDateHeader(date),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              theme.textTheme.bodySmall?.color?.withAlpha(179),
                        ),
                      ),
                    ),
                    item,
                  ],
                );
              } else {
                return item;
              }
            },
          );
        },
      ),
    );
  }
}
