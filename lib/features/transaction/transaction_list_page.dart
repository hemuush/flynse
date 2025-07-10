import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:flynse/features/transaction/add_edit_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => TransactionListPageState();
}

class TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // ViewMode is local to this page's filter sheet
  String _viewMode = 'Monthly';

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize local controllers and listeners
    final transactionProvider = context.read<TransactionProvider>();
    _searchController.text = transactionProvider.transactionSearchQuery;
    _viewMode = transactionProvider.transactionViewMode;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final appProvider = context.read<AppProvider>();
        context.read<TransactionProvider>().setTransactionFilters(
              year: appProvider.selectedYear,
              month: appProvider.selectedMonth,
              query: _searchController.text,
              viewMode: _viewMode,
            );
      }
    });
  }

  Future<void> _deleteTransaction(int id) async {
    final transactionProvider = context.read<TransactionProvider>();
    final appProvider = context.read<AppProvider>();

    await transactionProvider.deleteTransaction(id);
    await appProvider.refreshAllData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Locked'),
        content: const Text(
            'This transaction is linked to a Debt, Saving, or a Friend and must be managed from the corresponding page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFilterSortSheet() {
    final transactionProvider = context.read<TransactionProvider>();
    final appProvider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSortSheet(
        initialType: transactionProvider.transactionTypeFilter,
        initialSortBy: transactionProvider.transactionSortBy,
        initialSortAscending: transactionProvider.transactionSortAscending,
        initialViewMode: _viewMode,
        initialYear: appProvider.selectedYear,
        initialMonth: appProvider.selectedMonth,
        onApply: (type, sortBy, ascending, viewMode, year, month) {
          // When filters are applied, update the local viewMode state
          setState(() {
            _viewMode = viewMode;
          });
          // And trigger a refresh in the provider
          transactionProvider.setTransactionFilters(
              year: year,
              month: month,
              type: type,
              sortBy: sortBy,
              sortAscending: ascending,
              viewMode: viewMode);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers for changes
    final appProvider = context.watch<AppProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    // --- FIX: Check for period desynchronization and schedule a refresh ---
    final bool isPeriodOutOfSync = (appProvider.selectedYear != transactionProvider.currentYear) ||
                                  (_viewMode == 'Monthly' && appProvider.selectedMonth != transactionProvider.currentMonth);

    if (isPeriodOutOfSync) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Refresh the transaction data using the correct period from AppProvider
        transactionProvider.setTransactionFilters(
          year: appProvider.selectedYear,
          month: appProvider.selectedMonth,
          query: _searchController.text,
          viewMode: _viewMode,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(appProvider),
          Expanded(
            child: transactionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactionProvider.filteredTransactions.isEmpty
                    ? _buildEmptyState(context)
                    : _buildTransactionList(transactionProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0),
      itemCount: provider.filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = provider.filteredTransactions[index];
        final transactionDate = DateTime.parse(transaction['transaction_date']);

        bool showDateHeader;
        String headerText;

        if (_viewMode == 'Yearly') {
          final bool isFirstOfMonth = (index == 0) ||
              (transactionDate.month !=
                  DateTime.parse(provider.filteredTransactions[index - 1]
                          ['transaction_date'])
                      .month);
          showDateHeader = isFirstOfMonth;
          headerText = DateFormat.yMMMM().format(transactionDate);
        } else {
          showDateHeader = (index == 0) ||
              !isSameDay(
                  transactionDate,
                  DateTime.parse(provider.filteredTransactions[index - 1]
                      ['transaction_date']));
          headerText = formatDateHeader(transactionDate);
        }

        final type = transaction['type'] as String?;
        final category = transaction['category'] as String?;

        final isLocked = type == 'Saving' ||
            category == 'Loan' ||
            category == 'Debt Repayment' ||
            category == 'Savings Withdrawal' ||
            category == 'Friends' ||
            category == 'Friend Repayment';

        final transactionItem = _TransactionListItem(
          transaction: transaction,
          isLocked: isLocked,
          onTap: () {
            if (isLocked) {
              _showLockedDialog();
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddEditTransactionPage(
                  transaction: transaction,
                ),
              ));
            }
          },
        );

        final Widget dismissibleItem = isLocked
            ? transactionItem
            : Dismissible(
                key: ValueKey(transaction['id']),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: Text(
                                "Are you sure you want to delete this transaction: \"${transaction['description']}\"?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error),
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                },
                onDismissed: (direction) {
                  _deleteTransaction(transaction['id']);
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: transactionItem,
              );

        if (showDateHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, left: 8.0, bottom: 8.0),
                child: Text(
                  headerText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withAlpha(179),
                      ),
                ),
              ),
              dismissibleItem,
            ],
          );
        } else {
          return dismissibleItem;
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Transactions Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search for something else.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  // --- REFACTORED HEADER WIDGET ---
  Widget _buildHeader(AppProvider appProvider) {
    final theme = Theme.of(context);
    // Use the global period from appProvider for display
    String periodText = _viewMode == 'Monthly'
        ? 'Showing: ${_monthNames[appProvider.selectedMonth - 1]} ${appProvider.selectedYear}'
        : 'Showing: Year ${appProvider.selectedYear}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            periodText,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(25),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: _showFilterSortSheet,
                  tooltip: 'Filter & Sort',
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isLocked;
  final VoidCallback onTap;

  const _TransactionListItem({
    required this.transaction,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = transaction['type'] as String? ?? '';
    final color = _getColorForType(context, type);
    final iconData = _getIconForType(type);

    String title = transaction['description'];
    String subtitle = transaction['category'] as String? ?? '';
    if (transaction['sub_category'] != null &&
        transaction['sub_category'].isNotEmpty) {
      subtitle = '$subtitle (${transaction['sub_category']})';
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${NumberFormat.decimalPattern('en_IN').format(transaction['amount'])}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.lock,
                        size: 14,
                        color:
                            theme.colorScheme.onSurfaceVariant.withAlpha(128)),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    return switch (type) {
      'Income' => Icons.arrow_downward_rounded,
      'Saving' => Icons.savings_rounded,
      'Expense' => Icons.arrow_upward_rounded,
      _ => Icons.circle_outlined,
    };
  }

  Color _getColorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    return switch (type) {
      'Income' => theme.colorScheme.tertiary,
      'Saving' => Colors.lightGreen.shade500,
      'Expense' => theme.colorScheme.secondary,
      _ => theme.colorScheme.onSurface,
    };
  }
}

// --- REFACTORED FILTER SHEET WIDGET ---
class _FilterSortSheet extends StatefulWidget {
  final String initialType;
  final String initialSortBy;
  final bool initialSortAscending;
  final String initialViewMode;
  final int initialYear;
  final int initialMonth;
  final Function(String, String, bool, String, int, int) onApply;

  const _FilterSortSheet({
    required this.initialType,
    required this.initialSortBy,
    required this.initialSortAscending,
    required this.initialViewMode,
    required this.initialYear,
    required this.initialMonth,
    required this.onApply,
  });

  @override
  State<_FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<_FilterSortSheet> {
  late String _selectedType;
  late String _sortBy;
  late bool _sortAscending;
  late String _selectedViewMode;
  late int _selectedYear;
  late int _selectedMonth;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _sortBy = widget.initialSortBy;
    _sortAscending = widget.initialSortAscending;
    _selectedViewMode = widget.initialViewMode;
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final appProvider = context.read<AppProvider>();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // --- PERIOD AND VIEW SELECTION ---
            Text('View Options', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                    value: 'Monthly',
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month_outlined)),
                ButtonSegment<String>(
                    value: 'Yearly',
                    label: Text('Yearly'),
                    icon: Icon(Icons.calendar_today_outlined)),
              ],
              selected: {_selectedViewMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedViewMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    items: appProvider.availableYears
                        .map((year) => DropdownMenuItem(
                            value: year, child: Text(year.toString())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          // If the new year doesn't have the currently selected month, reset it
                          if (!appProvider.getAvailableMonthsForYear(value).contains(_selectedMonth)) {
                            _selectedMonth = appProvider.getAvailableMonthsForYear(value).first;
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(
                        labelText: 'Year',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ),
                if (_selectedViewMode == 'Monthly') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      items: appProvider
                          .getAvailableMonthsForYear(_selectedYear)
                          .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(_monthNames[month - 1])))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                          labelText: 'Month',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)),
                    ),
                  ),
                ]
              ],
            ),

            const Divider(height: 32),

            // --- FILTER BY TYPE ---
            Text('Filter by Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: ['All', 'Income', 'Expense', 'Saving'].map((type) {
                return _buildStyledChip(
                  context: context,
                  label: type,
                  isSelected: _selectedType == type,
                  onTap: () => setState(() => _selectedType = type),
                );
              }).toList(),
            ),

            const Divider(height: 32),

            // --- SORT OPTIONS ---
            Text('Sort by', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSortOption(
              context: context,
              label: 'Date',
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context: context,
              label: 'Amount',
              value: 'amount',
              groupValue: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
            const Divider(height: 32),
            Text('Sort Order', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStyledChip(
                    context: context,
                    label: 'Ascending',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: _sortAscending,
                    onTap: () => setState(() => _sortAscending = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStyledChip(
                    context: context,
                    label: 'Descending',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: !_sortAscending,
                    onTap: () => setState(() => _sortAscending = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    )),
                onPressed: () {
                  widget.onApply(_selectedType, _sortBy, _sortAscending,
                      _selectedViewMode, _selectedYear, _selectedMonth);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant),
              if (icon != null) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withAlpha(25)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: theme.colorScheme.primary,
              ),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}