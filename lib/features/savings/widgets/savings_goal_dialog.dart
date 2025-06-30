import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:provider/provider.dart';

class SavingsGoalDialog extends StatefulWidget {
  final Map<String, dynamic>? currentGoal;
  const SavingsGoalDialog({super.key, this.currentGoal});

  @override
  State<SavingsGoalDialog> createState() => _SavingsGoalDialogState();
}

class _SavingsGoalDialogState extends State<SavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentGoal != null) {
      _nameController.text = widget.currentGoal!['name'];
      _amountController.text =
          (widget.currentGoal!['target_amount'] as double).toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = context.read<SavingsProvider>();
    final appProvider = context.read<AppProvider>();
    final navigator = Navigator.of(context);
    final bool isEditMode = widget.currentGoal != null;

    return AlertDialog(
      title: Text(isEditMode ? 'Edit Savings Goal' : 'Set a Savings Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Goal Name'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter an amount';
                final amount = double.tryParse(v);
                if (amount == null) return 'Enter a valid number';
                if (amount <= 0) return 'Amount must be positive';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        if (isEditMode)
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: const Text('Are you sure you want to delete your active savings goal?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await savingsProvider.deleteActiveSavingsGoal();
                await appProvider.refreshAllData();
                if (navigator.mounted) navigator.pop();
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              final name = _nameController.text;
              await savingsProvider.setSavingsGoal(name, amount);
              await appProvider.refreshAllData();
              if (navigator.mounted) navigator.pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}