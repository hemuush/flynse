import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/category_repository.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:intl/intl.dart';

// --- TYPE SELECTOR ---
class TypeSelector extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const TypeSelector({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'Expense',
            label: Text('Expense'),
            icon: Icon(Icons.arrow_upward_rounded)),
        ButtonSegment(
            value: 'Income',
            label: Text('Income'),
            icon: Icon(Icons.arrow_downward_rounded)),
        ButtonSegment(
            value: 'Saving',
            label: Text('Saving'),
            icon: Icon(Icons.savings_rounded)),
      ],
      selected: {formState.type},
      onSelectionChanged: (newSelection) {
        formState.type = newSelection.first;
        formState.category = null;
        formState.subCategories = [];
        formState.selectedFriend = null;
        formState.selectedDebtForRepayment = null;
        formState.selectedCategoryForWithdrawal = null;
        formState.isSplit = false;
        onStateChanged();
      },
    );
  }
}

// --- AMOUNT AND DATE SECTION ---
class AmountAndDateSection extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const AmountAndDateSection({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: formState.amountController,
                readOnly: formState.isSplit,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: InputBorder.none,
                  labelStyle: TextStyle(
                    color: formState.isSplit ? theme.colorScheme.primary : null,
                  ),
                ),
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: formState.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != formState.date) {
                  formState.date = picked;
                  onStateChanged();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(128)),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('MMM').format(formState.date).toUpperCase(),
                        style: theme.textTheme.bodySmall),
                    Text(DateFormat('dd').format(formState.date),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy').format(formState.date),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- CATEGORY SECTION ---
class CategorySection extends StatelessWidget {
  final TransactionFormState formState;
  final bool isTryingToSubmit;
  final VoidCallback onStateChanged;
  final Future<String?> Function(BuildContext, {required String title, required String label}) showAddDialog;
  final bool isLocked;

  const CategorySection({
    super.key,
    required this.formState,
    required this.isTryingToSubmit,
    required this.onStateChanged,
    required this.showAddDialog,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryRepo = CategoryRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Category', style: theme.textTheme.titleMedium),
            if (formState.category != null)
              InputChip(
                label: Text(formState.category!['name']),
                onDeleted: isLocked ? null : () {
                  formState.category = null;
                  onStateChanged();
                },
              ),
          ],
        ),
        if (formState.category == null) ...[
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: categoryRepo.getCategories(formState.type),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ...snapshot.data!.map((category) => ChoiceChip(
                        label: Text(category['name']),
                        selected: false,
                        onSelected: (selected) {
                          formState.category = category;
                          onStateChanged();
                        },
                      )),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                    onPressed: () async {
                      final newCategoryName = await showAddDialog(
                        context,
                        title: 'Add New Category',
                        label: 'Category Name',
                      );
                      if (newCategoryName != null &&
                          newCategoryName.isNotEmpty) {
                        final id = await categoryRepo.insertCategory(
                            {'name': newCategoryName, 'type': formState.type});
                        formState.category = {
                          'id': id,
                          'name': newCategoryName,
                          'type': formState.type
                        };
                        onStateChanged();
                      }
                    },
                  ),
                ],
              );
            },
          ),
          if (isTryingToSubmit && formState.category == null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please select a category',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ]
      ],
    );
  }
}

// --- SUB-CATEGORY SELECTOR ---
class SubCategorySelector extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;
  final Function(TransactionFormState) syncSplits;
  final Future<String?> Function({required String title, required String label}) showAddDialog;

  const SubCategorySelector({
    super.key,
    required this.formState,
    required this.onStateChanged,
    required this.syncSplits,
    required this.showAddDialog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryRepo = CategoryRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sub-Category (Optional)', style: theme.textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add New'),
              onPressed: () async {
                final newSubCategoryName = await showAddDialog(
                  title: 'Add Sub-Category',
                  label: 'Sub-Category Name',
                );
                if (newSubCategoryName != null &&
                    newSubCategoryName.isNotEmpty) {
                  await categoryRepo.insertSubCategory({
                    'name': newSubCategoryName,
                    'category_id': formState.category!['id']
                  });
                  onStateChanged(); // Rebuild to show the new sub-category
                }
              },
            )
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: formState.subCategories.map((subCategory) {
            return InputChip(
              label: Text(subCategory),
              onDeleted: () {
                formState.subCategories.remove(subCategory);
                if (formState.subCategories.length <= 1) {
                  formState.isSplit = false;
                }
                syncSplits(formState);
                onStateChanged();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: categoryRepo.getSubCategories(formState.category!['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final availableSubCats = snapshot.data!
                .where((sc) => !formState.subCategories.contains(sc['name']))
                .toList();

            if (availableSubCats.isEmpty) return const SizedBox.shrink();

            return Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: availableSubCats.map((subCategory) {
                return ChoiceChip(
                  label: Text(subCategory['name']),
                  selected: false,
                  onSelected: (selected) {
                    formState.subCategories.add(subCategory['name']);
                    if (formState.subCategories.length > 1) {
                      formState.isSplit = true;
                    }
                    syncSplits(formState);
                    onStateChanged();
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// --- SPLIT AMOUNT EDITOR ---
class SplitAmountEditor extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;

  const SplitAmountEditor({
    super.key,
    required this.formState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split Amounts', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...formState.splits.map((split) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      split.subCategory ?? 'Main',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: split.amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onStateChanged(),
                      validator: (v) {
                        if (formState.isSplit) {
                          if (v == null || v.isEmpty) return 'Req.';
                          if (double.tryParse(v) == null) return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// --- LOAN DETAILS SECTION ---
class LoanDetailsSection extends StatelessWidget {
    final TransactionFormState formState;
    final VoidCallback onStateChanged;

    const LoanDetailsSection({
        super.key,
        required this.formState,
        required this.onStateChanged,
    });

    @override
    Widget build(BuildContext context) {
        return Column(
        children: [
            TextFormField(
            controller: formState.loanNameController,
            decoration: const InputDecoration(labelText: 'Loan Name'),
            validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
            controller: formState.interestController,
            decoration:
                const InputDecoration(labelText: 'Interest Rate % (Optional)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
            controller: formState.termController,
            decoration:
                const InputDecoration(labelText: 'Loan Term in Years (Optional)'),
            keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
            title: const Text('This is a purchase on EMI'),
            value: formState.isEmiPurchase,
            onChanged: (bool value) {
                formState.isEmiPurchase = value;
                onStateChanged();
            },
            contentPadding: EdgeInsets.zero,
            ),
            if (formState.isEmiPurchase) ...[
            const SizedBox(height: 16),
            TextFormField(
                controller: formState.purchaseDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Item/Service Purchased'),
                validator: (v) {
                if (formState.isEmiPurchase && v!.isEmpty) {
                    return 'Please describe the purchase';
                }
                return null;
                },
            ),
            ]
        ],
        );
    }
}


// --- EXPENSE DETAILS SECTION ---
class ExpenseDetailsSection extends StatelessWidget {
  final TransactionFormState formState;
  final VoidCallback onStateChanged;
  final Function(TransactionFormState) syncSplits;
  final Future<String?> Function({required String title, required String label}) showAddDialog;

  const ExpenseDetailsSection({
    super.key,
    required this.formState,
    required this.onStateChanged,
    required this.syncSplits,
    required this.showAddDialog,
  });

  @override
  Widget build(BuildContext context) {
    if (formState.category == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubCategorySelector(
          formState: formState,
          onStateChanged: onStateChanged,
          syncSplits: syncSplits,
          showAddDialog: showAddDialog,
        ),
        if (formState.isSplit) ...[
          const Divider(height: 32),
          SplitAmountEditor(
            formState: formState,
            onStateChanged: onStateChanged,
          ),
        ]
      ],
    );
  }
}
