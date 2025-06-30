import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyDetailsSheet extends StatelessWidget {
  const MonthlyDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();
    final appProvider = context.watch<AppProvider>();
    final monthName =
        DateFormat.MMMM().format(DateTime(0, appProvider.selectedMonth));

    // Monthly totals
    final income = provider.monthlyTotals['Income'] ?? 0.0;
    final expense = provider.monthlyTotals['Expense'] ?? 0.0;
    final saving = provider.monthlyTotals['Saving'] ?? 0.0;
    final monthlyNet = income - expense - saving;
    final breakdown = provider.monthlyCategoryBreakdown;

    // Cumulative totals
    final cumulativeIncome = provider.cumulativeTotals['Income'] ?? 0.0;
    final cumulativeExpense = provider.cumulativeTotals['Expense'] ?? 0.0;
    final cumulativeSaving = provider.cumulativeTotals['Saving'] ?? 0.0;
    final cumulativeBalance = cumulativeIncome - cumulativeExpense - cumulativeSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Details for $monthName ${appProvider.selectedYear}',
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          // --- MODIFIED: Display both monthly and cumulative balances ---
          _buildMoneyLeft(theme, monthlyNet, "Net for $monthName"),
          const SizedBox(height: 16),
          _buildMoneyLeft(theme, cumulativeBalance, "Balance till End of Month"),
          const Divider(height: 32),
          Text('Summary for $monthName', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildSummaryRow(theme, 'Income', income, theme.colorScheme.tertiary),
          const SizedBox(height: 8),
          _buildSummaryRow(
              theme, 'Expense', expense, theme.colorScheme.secondary),
          const SizedBox(height: 8),
          _buildSummaryRow(theme, 'Saving', saving, Colors.lightGreen.shade400),
          const Divider(height: 32),
          Text('Expense Breakdown for $monthName', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildExpenseBreakdown(theme, breakdown),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // MODIFIED: Helper accepts a title now
  Widget _buildMoneyLeft(ThemeData theme, double money, String title) {
    return Center(
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat.decimalPattern().format(money)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: money >= 0
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.error,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      ThemeData theme, String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        Text(
          '₹${NumberFormat.decimalPattern().format(value)}',
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdown(
      ThemeData theme, List<Map<String, dynamic>> breakdown) {
    if (breakdown.isEmpty) {
      return const Center(child: Text('No expense data for this period.'));
    }
    // --- MODIFIED: Wrapped the list in a ConstrainedBox and used a ListView ---
    // This makes the list scrollable if its content exceeds the max height.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView(
        shrinkWrap: true,
        children: breakdown
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['category'], style: theme.textTheme.bodyMedium),
                      Text(
                        '₹${NumberFormat.decimalPattern().format(item['total'])}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
