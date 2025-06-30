import 'package:flutter/material.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavingsWithdrawalSelector extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const SavingsWithdrawalSelector({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SavingsProvider>(
      builder: (context, provider, child) {
        final savingsByCategory = provider.savingsByCategory;

        if (savingsByCategory.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(128)),
            ),
            child: const Center(
              child: Text('No savings available to withdraw from.'),
            ),
          );
        }

        final availableCategoryNames =
            savingsByCategory.map((c) => c['category'] as String).toList();
        final isCurrentValueValid = formState.selectedCategoryForWithdrawal != null &&
            availableCategoryNames.contains(formState.selectedCategoryForWithdrawal);

        return DropdownButtonFormField<String>(
          value: isCurrentValueValid ? formState.selectedCategoryForWithdrawal : null,
          items: savingsByCategory.map((category) {
            return DropdownMenuItem<String>(
              value: category['category'] as String,
              child: Text(
                  '${category['category']} (${NumberFormat.simpleCurrency(locale: 'en_IN').format(category['total'])})'),
            );
          }).toList(),
          onChanged: (selectedCategoryName) {
            formState.selectedCategoryForWithdrawal = selectedCategoryName;
            onStateChanged();
          },
          decoration:
              const InputDecoration(labelText: 'Withdraw From'),
          validator: (v) => v == null ? 'Please select a source category' : null,
        );
      },
    );
  }
}
