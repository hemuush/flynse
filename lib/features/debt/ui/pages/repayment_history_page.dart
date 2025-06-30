import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:flynse/features/debt/ui/pages/debt_schedule_page.dart';
import 'package:flynse/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RepaymentHistoryPage extends StatefulWidget {
  final Map<String, dynamic> debt;

  const RepaymentHistoryPage({super.key, required this.debt});

  @override
  State<RepaymentHistoryPage> createState() => _RepaymentHistoryPageState();
}

class _RepaymentHistoryPageState extends State<RepaymentHistoryPage> {
  final DebtRepository _debtRepo = DebtRepository();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _debtRepo.getRepaymentHistory(widget.debt['id']);
    });
  }

  void _navigateToSchedule() {
    // Navigate to the schedule page, which will handle its own calculations.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DebtSchedulePage(debt: widget.debt),
    ));
  }

  Future<void> _deleteTransaction(int transactionId) async {
    await context.read<TransactionProvider>().deleteTransaction(transactionId);
    if (!mounted) return;
    await context.read<AppProvider>().refreshAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repayment deleted successfully')),
      );
      _loadHistory(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bool canShowSchedule =
        (widget.debt['interest_rate'] as num? ?? 0) > 0 &&
            (widget.debt['loan_term_years'] as num? ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('History for ${widget.debt['name']}'),
        actions: [
          if (canShowSchedule)
            IconButton(
              icon: const Icon(Icons.calculate_outlined),
              onPressed: _navigateToSchedule,
              tooltip: 'View Loan Schedule',
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No repayment history found for this debt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final history = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final repayment = history[index];
              final date = DateTime.parse(repayment['transaction_date']);
              final amount = repayment['amount'] as double;
              final description = repayment['description'] as String;
              final prepaymentOption = repayment['prepayment_option'] as String?;

              // --- MODIFICATION START: Build subtitle with prepayment info ---
              String subtitleText = formatDateHeader(date);
              if (prepaymentOption != null) {
                if (prepaymentOption == 'reduce_emi') {
                  subtitleText += ' (Reduced EMI)';
                } else if (prepaymentOption == 'reduce_tenure') {
                  subtitleText += ' (Reduced Tenure)';
                }
              }
              // --- MODIFICATION END ---

              final repaymentCard = Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.payment_rounded),
                  title: Text(description),
                  subtitle: Text(subtitleText), // Use the new subtitle
                  trailing: Text(
                    '₹${NumberFormat.decimalPattern().format(amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              );

              return Dismissible(
                key: ValueKey(repayment['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteTransaction(repayment['id']);
                },
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete this repayment of ₹${amount.toStringAsFixed(2)}? This will update the debt balance.'),
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
                child: repaymentCard,
              );
            },
          );
        },
      ),
    );
  }
}
