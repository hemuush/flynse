import 'package:flutter/material.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:provider/provider.dart';

class FriendRepaymentSelector extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const FriendRepaymentSelector({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();
    // FIX: Changed friendLoans to loansToFriends to match the provider.
    final debtsOwedToUser = friendProvider.loansToFriends;

    if (debtsOwedToUser.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(128)),
        ),
        child: const Center(
          child: Text('No active loans to friends found.'),
        ),
      );
    }

    // --- MODIFICATION: Add validation to amount field ---
    final selectedDebt = formState.selectedDebtForRepayment;
    double remainingAmount = 0;
    if (selectedDebt != null) {
      remainingAmount = (selectedDebt['total_amount'] as double) - (selectedDebt['amount_paid'] as double);
    }

    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: formState.selectedDebtForRepayment?['id'] as int?,
          items: debtsOwedToUser.map((d) {
            final remaining = (d['total_amount'] - d['amount_paid']);
            return DropdownMenuItem<int>(
              value: d['id'] as int,
              child: Text("${d['name']} (Owes ₹${(remaining).toStringAsFixed(2)})"),
            );
          }).toList(),
          onChanged: (selectedId) {
            if (selectedId == null) return;

            final selectedDebt =
                debtsOwedToUser.firstWhere((d) => d['id'] == selectedId);
            formState.selectedDebtForRepayment = selectedDebt;

            final remaining =
                selectedDebt['total_amount'] - selectedDebt['amount_paid'];
            formState.amountController.text =
                remaining > 0 ? remaining.toStringAsFixed(2) : '';
            onStateChanged();
          },
          decoration: const InputDecoration(labelText: 'Select Loan to be Repaid'),
          validator: (v) => v == null ? 'Please select a loan' : null,
        ),
        if (selectedDebt != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: formState.amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter an amount';
              final amount = double.tryParse(v);
              if (amount == null) return 'Enter a valid number';
              if (amount <= 0) return 'Amount must be positive';
              if (amount > remainingAmount) {
                return 'Amount cannot exceed what is owed: ₹${remainingAmount.toStringAsFixed(2)}';
              }
              return null;
            },
          )
        ]
      ],
    );
  }
}
