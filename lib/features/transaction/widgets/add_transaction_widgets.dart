import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/category_repository.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    return Row(
      children: [
        _buildTypeChip(context, type: 'Expense', icon: Icons.arrow_upward_rounded),
        const SizedBox(width: 8),
        _buildTypeChip(context, type: 'Income', icon: Icons.arrow_downward_rounded),
        const SizedBox(width: 8),
        _buildTypeChip(context, type: 'Saving', icon: Icons.savings_rounded),
      ],
    );
  }

  Widget _buildTypeChip(BuildContext context, {required String type, required IconData icon}) {
    final theme = Theme.of(context);
    final isSelected = formState.type == type;

    return Expanded(
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            formState.type = type;
            formState.category = null;
            formState.subCategories = [];
            formState.selectedFriend = null;
            formState.selectedDebtForRepayment = null;
            formState.selectedCategoryForWithdrawal = null;
            formState.isSplit = false;
            onStateChanged();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  type,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
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
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, child) {
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color:
                              formState.isSplit ? theme.colorScheme.primary : null),
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

                      if (formState.isSavingsWithdrawal) {
                        final selectedCategoryName =
                            formState.selectedCategoryForWithdrawal;
                        if (selectedCategoryName != null) {
                          final savingsByCategory =
                              savingsProvider.savingsByCategory;
                          try {
                            final categoryData = savingsByCategory.firstWhere(
                              (c) => c['category'] == selectedCategoryName,
                            );
                            final categoryTotal = categoryData['total'] as double;
                            if (amount > categoryTotal) {
                              return 'Exceeds category total of ${NumberFormat.simpleCurrency(locale: 'en_IN').format(categoryTotal)}';
                            }
                          } catch (e) {
                            // Category not found, should not happen if selected
                          }
                        }
                      }
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
                            color: theme.colorScheme.outline.withAlpha(128))),
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
      },
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

    if (formState.category != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Category',
            style: theme.textTheme.titleMedium,
          ),
          InputChip(
            label: Text(formState.category!['name']),
            labelStyle: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
            selectedColor: theme.colorScheme.secondaryContainer,
            checkmarkColor: theme.colorScheme.onSecondaryContainer,
            selected: true,
            onDeleted: isLocked ? null : () {
              formState.category = null;
              onStateChanged();
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitledChipSelectionGrid<Map<String, dynamic>>(
          title: 'Category',
          itemsFuture: categoryRepo.getCategories(formState.type),
          itemBuilder: (category) => ChoiceChip(
            label: Text(category['name']),
            selected: formState.category?['id'] == category['id'],
            onSelected: (selected) {
              if (selected) {
                formState.category = category;
                formState.subCategories = [];
                formState.isSplit = false;
                onStateChanged();
              }
            },
          ),
          onAddNew: () async {
            final newCategoryName = await showAddDialog(
              context,
              title: 'Add New Category',
              label: 'Category Name',
            );
            if (newCategoryName != null && newCategoryName.isNotEmpty) {
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
        if (isTryingToSubmit && formState.category == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              'Please select a category',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
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
        _buildSubCategorySection(context),
        if (formState.isSplit) ...[
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child:
                Text('Split Amounts', style: Theme.of(context).textTheme.titleMedium),
          ),
          _buildSplitSection(context)
        ],
      ],
    );
  }

  Widget _buildSubCategorySection(BuildContext context) {
    final categoryRepo = CategoryRepository();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formState.subCategories.isNotEmpty)
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
        _TitledChipSelectionGrid<Map<String, dynamic>>(
          title: 'Sub-Category (Optional)',
          itemsFuture: categoryRepo.getSubCategories(formState.category!['id']),
          itemBuilder: (subCategory) => ChoiceChip(
            label: Text(subCategory['name']),
            selected: false, // It's always for adding new ones
            onSelected: (selected) {
                formState.subCategories.add(subCategory['name']);
                  if (formState.subCategories.length > 1) {
                  formState.isSplit = true;
                    syncSplits(formState);
                }
                onStateChanged();
            },
          ),
          onAddNew: () async {
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
                if (!formState.subCategories.contains(newSubCategoryName)) {
                  formState.subCategories.add(newSubCategoryName);
                    if (formState.subCategories.length > 1) {
                    formState.isSplit = true;
                      syncSplits(formState);
                  }
                    onStateChanged();
                }
            }
          },
        ),
      ],
    );
  }

  Widget _buildSplitSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...formState.splits.map((split) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Expanded(
                    flex: 3,
                    child: TextFormField(
                          key: ValueKey(split.subCategory),
                          initialValue: split.subCategory,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Sub-Category',
                            border: InputBorder.none, 
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// A generic private widget to display a grid of selectable chips from a future.
/// This reduces code duplication between the Category and Sub-Category sections.
class _TitledChipSelectionGrid<T> extends StatelessWidget {
  final String title;
  final Future<List<T>> itemsFuture;
  final Widget Function(T item) itemBuilder;
  final VoidCallback onAddNew;

  const _TitledChipSelectionGrid({
    required this.title,
    required this.itemsFuture,
    required this.itemBuilder,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: onAddNew,
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<T>>(
          future: itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 52,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 52,
                child: Center(child: Text('Error loading items.')),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const SizedBox(
                height: 52,
                child: Center(
                  child: Text('No items to show.'),
                ),
              );
            }

            return SizedBox(
              height: 104,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 0.4,
                ),
                itemBuilder: (context, index) {
                  return itemBuilder(items[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
