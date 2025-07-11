import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/settings/friend_history_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A card widget specifically for displaying debts related to friends.
class FriendDebtCard extends StatefulWidget {
  final Map<String, dynamic> debt;

  const FriendDebtCard({super.key, required this.debt});

  @override
  State<FriendDebtCard> createState() => _FriendDebtCardState();
}

class _FriendDebtCardState extends State<FriendDebtCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isUserDebtor = widget.debt['is_user_debtor'] == 1;

    final double totalAmount = widget.debt['total_amount'] as double;
    final double amountPaid = widget.debt['amount_paid'] as double;
    final double progress =
        totalAmount > 0 ? (amountPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedAmountPaid = nf.format(amountPaid);
    final formattedTotalAmount = nf.format(totalAmount);

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
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(widget.debt['name'],
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(isUserDebtor
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.tertiary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      isUserDebtor
                          ? 'Paid: $formattedAmountPaid'
                          : 'Received: $formattedAmountPaid',
                      style: theme.textTheme.bodySmall),
                  Text('Total: $formattedTotalAmount',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? _buildExpandedDetails(context)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isUserDebtor = widget.debt['is_user_debtor'] == 1;
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    
    final totalAmount = widget.debt['total_amount'] as double;
    final amountPaid = widget.debt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Remaining Amount", style: theme.textTheme.bodyMedium),
              Text(nf.format(remainingAmount),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('View History'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FriendHistoryPage(
                    friendId: widget.debt['friend_id'],
                    friendName: widget.debt['name'],
                  ),
                ));
              },
            ),
            FilledButton.tonalIcon(
              icon: Icon(isUserDebtor ? Icons.payment : Icons.add_card_rounded, size: 18),
              label: Text(isUserDebtor ? 'Pay' : 'Receive'),
              onPressed: () => _showPaymentDialog(context, widget.debt),
            ),
          ],
        ),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> debt) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final debtProvider = context.read<DebtProvider>();
    final friendProvider = context.read<FriendProvider>();
    final appProvider = context.read<AppProvider>();

    final isUserDebtor = debt['is_user_debtor'] == 1;
    final totalAmount = debt['total_amount'] as double;
    final amountPaid = debt['amount_paid'] as double;
    final remainingAmount = totalAmount - amountPaid;

    final now = DateTime.now();
    final transactionDate =
        (appProvider.selectedYear == now.year && appProvider.selectedMonth == now.month)
            ? now
            : DateTime(appProvider.selectedYear, appProvider.selectedMonth, 1);

    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(isUserDebtor ? 'Pay ${debt['name']}' : 'Receive Payment from ${debt['name']}'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid number';
                  if (amount <= 0) return 'Amount must be positive';
                  if (amount > remainingAmount + 0.01) {
                     return 'Amount cannot exceed what is owed (${NumberFormat.simpleCurrency(locale: 'en_IN').format(remainingAmount)})';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop();
                    final amount = double.parse(amountController.text);
                    
                    if (isUserDebtor) {
                      await debtProvider.addRepayment(
                          debt['id'],
                          'Payment to ${debt['name']}',
                          amount,
                          transactionDate);
                    } else {
                      await friendProvider.addRepaymentFromFriend(
                          debt['id'],
                          'Payment from ${debt['name']}',
                          amount,
                          transactionDate);
                    }
                    await appProvider.refreshAllData();
                  }
                },
                child: Text(isUserDebtor ? 'Pay' : 'Receive'),
              ),
            ],
          );
        });
  }
}
