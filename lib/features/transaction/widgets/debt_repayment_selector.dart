import 'package:flutter/material.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:provider/provider.dart';

class DebtRepaymentSelector extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const DebtRepaymentSelector({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final userDebts = debtProvider.userDebts;

    if (userDebts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(128)),
        ),
        child: const Center(
          child: Text('No active debts available to repay.'),
        ),
      );
    }

    // --- MODIFICATION: Add validation to amount field ---
    final selectedDebt = formState.selectedDebtForUserRepayment;
    double remainingAmount = 0;
    if (selectedDebt != null) {
      remainingAmount = (selectedDebt['total_amount'] as double) - (selectedDebt['amount_paid'] as double);
    }

    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: formState.selectedDebtForUserRepayment?['id'] as int?,
          items: userDebts.map((d) {
            final remaining = (d['total_amount'] - d['amount_paid']);
            return DropdownMenuItem<int>(
              value: d['id'] as int,
              child: Text("${d['name']} (Owes ₹${(remaining).toStringAsFixed(2)})"),
            );
          }).toList(),
          onChanged: (selectedId) {
            if (selectedId == null) return;

            final selectedDebt =
                userDebts.firstWhere((d) => d['id'] == selectedId);
            formState.selectedDebtForUserRepayment = selectedDebt;
            formState.amountController.text = '';
            onStateChanged();
          },
          decoration: const InputDecoration(labelText: 'Select Debt to Repay'),
          validator: (v) => v == null ? 'Please select a debt' : null,
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
                return 'Amount cannot exceed the remaining balance of ₹${remainingAmount.toStringAsFixed(2)}';
              }
              return null;
            },
          )
        ]
      ],
    );
  }
}
