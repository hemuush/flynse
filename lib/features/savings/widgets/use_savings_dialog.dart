import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UseSavingsDialog extends StatefulWidget {
  const UseSavingsDialog({super.key});

  @override
  State<UseSavingsDialog> createState() => _UseSavingsDialogState();
}

class _UseSavingsDialogState extends State<UseSavingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<SavingsProvider>(
      builder: (context, provider, child) {
        final savingsByCategory = provider.savingsByCategory;
        final appProvider = context.read<AppProvider>();
        final navigator = Navigator.of(context);

        // --- FIX: Ensure selected category is valid ---
        final availableCategories =
            savingsByCategory.map((c) => c['category'] as String).toList();
        if (_selectedCategory != null &&
            !availableCategories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }

        return AlertDialog(
          title: const Text('Use Savings'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NEW: Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'From Category'),
                  items: savingsByCategory.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['category'],
                      child: Text(
                          '${category['category']} (${NumberFormat.simpleCurrency(locale: 'en_IN').format(category['total'])})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(v);
                    if (amount == null) return 'Enter a valid number';
                    if (amount <= 0) return 'Amount must be positive';
                    if (_selectedCategory != null) {
                      final categoryTotal = savingsByCategory
                          .firstWhere((c) =>
                              c['category'] == _selectedCategory)['total'] as double;
                      if (amount > categoryTotal) {
                        return 'Amount cannot exceed the category total';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text);
                  final description = _descriptionController.text;

                  final now = DateTime.now();
                  final selectedYear = appProvider.selectedYear;
                  final selectedMonth = appProvider.selectedMonth;
                  late DateTime transactionDate;

                  if (selectedYear == now.year && selectedMonth == now.month) {
                    transactionDate = now;
                  } else {
                    transactionDate =
                        DateTime(selectedYear, selectedMonth + 1, 0);
                  }

                  await provider.useSavings(
                      amount,
                      _selectedCategory!,
                      description.isNotEmpty ? description : null,
                      transactionDate);
                  await appProvider.refreshAllData();
                  HapticFeedback.mediumImpact();
                  if (navigator.mounted) navigator.pop();
                }
              },
              child: const Text('Use'),
            ),
          ],
        );
      },
    );
  }
}