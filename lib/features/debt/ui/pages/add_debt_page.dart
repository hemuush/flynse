import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddDebtPage extends StatefulWidget {
  const AddDebtPage({super.key});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _termController = TextEditingController();
  final _purchaseDescriptionController = TextEditingController();
  bool _isEmiPurchase = false;
  late DateTime _transactionDate;
  late DateTime _loanStartDate;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final now = DateTime.now();
    final year = provider.selectedYear;
    final month = provider.selectedMonth;

    if (year == now.year && month == now.month) {
      _transactionDate = now;
    } else {
      _transactionDate = DateTime(year, month, 1);
    }
    // Default the loan start date to the transaction date initially
    _loanStartDate = _transactionDate;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final debtProvider = context.read<DebtProvider>();
      final appProvider = context.read<AppProvider>();
      final navigator = Navigator.of(context);

      final now = DateTime.now();
      final isToday = _transactionDate.year == now.year &&
          _transactionDate.month == now.month &&
          _transactionDate.day == now.day;
      final transactionDateForDb = isToday ? now : _transactionDate;

      await debtProvider.addDebt({
        'name': _nameController.text,
        'amount': double.parse(_amountController.text),
        // MODIFICATION: Parse interest rate as a double.
        'interest_rate': _interestController.text.isNotEmpty
            ? double.parse(_interestController.text)
            : null,
        'loan_term_years':
            _termController.text.isNotEmpty ? int.parse(_termController.text) : null,
        'date': transactionDateForDb.toIso8601String(),
        'loan_start_date': _loanStartDate.toIso8601String(), // Pass the loan start date
        'is_emi_purchase': _isEmiPurchase,
        'purchase_description': _purchaseDescriptionController.text,
      });

      await appProvider.refreshAllData();

      if (navigator.mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Loan / Debt'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        label: const Text('Save Debt'),
        icon: const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Principal Amount',
                        prefixText: '₹',
                      ),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v!.isEmpty) return 'Please enter an amount';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Loan Name / Lender'),
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter a name' : null,
                    ),
                     const SizedBox(height: 16),
                    // --- MODIFICATION: Date Pickers ---
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker(context, 'Transaction Date', _transactionDate, (date) => setState(() => _transactionDate = date))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDatePicker(context, 'Loan Start Date', _loanStartDate, (date) => setState(() => _loanStartDate = date), allowFuture: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // MODIFICATION: Changed keyboardType and removed inputFormatters.
                    TextFormField(
                      controller: _interestController,
                      decoration: const InputDecoration(
                          labelText: 'Interest Rate % (Optional)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (double.tryParse(v) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _termController,
                      decoration: const InputDecoration(
                          labelText: 'Loan Term in Years (Optional)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (int.tryParse(v) == null) {
                          return 'Please enter a valid whole number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('This is a purchase on EMI'),
                      value: _isEmiPurchase,
                      onChanged: (bool value) {
                        setState(() {
                          _isEmiPurchase = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    if (_isEmiPurchase) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purchaseDescriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Item/Service Purchased'),
                        validator: (v) {
                          if (_isEmiPurchase && v!.isEmpty) {
                            return 'Please describe the purchase';
                          }
                          return null;
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime date, Function(DateTime) onDateChanged, {bool allowFuture = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: allowFuture ? DateTime(2101) : DateTime.now(),
        );
        if (picked != null && picked != date) {
          onDateChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
         decoration: InputDecoration(
           labelText: label,
           contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
           border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(128))
           )
         ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Column(
              children: [
                Text(DateFormat('MMM').format(date).toUpperCase(),
                    style: theme.textTheme.bodySmall),
                Text(DateFormat('dd').format(date),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 8),
            Text(DateFormat('yyyy').format(date),
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
