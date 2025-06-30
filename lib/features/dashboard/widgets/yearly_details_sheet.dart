import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class YearlyDetailsSheet extends StatelessWidget {
  const YearlyDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<AppProvider, AnalyticsProvider>(
      builder: (context, appProvider, analyticsProvider, child) {

        final income = analyticsProvider.yearlyTotals['Income'] ?? 0.0;
        final expense = analyticsProvider.yearlyTotals['Expense'] ?? 0.0;
        final saving = analyticsProvider.yearlyTotals['Saving'] ?? 0.0;
        final moneyLeft = income - expense - saving;
        final breakdown = analyticsProvider.yearlyCategoryBreakdown;

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
                  'Yearly Details for ${appProvider.selectedYear}',
                  style:
                      theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              _buildMoneyLeft(theme, moneyLeft),
              const Divider(height: 32),
              Text('Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildSummaryRow(theme, 'Income', income, theme.colorScheme.tertiary),
              const SizedBox(height: 8),
              _buildSummaryRow(
                  theme, 'Expense', expense, theme.colorScheme.secondary),
              const SizedBox(height: 8),
              _buildSummaryRow(theme, 'Saving', saving, Colors.lightGreen.shade400),
              const Divider(height: 32),
              Text('Expense Breakdown', style: theme.textTheme.titleMedium),
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
    );
  }

  Widget _buildMoneyLeft(ThemeData theme, double moneyLeft) {
    return Center(
      child: Column(
        children: [
          Text(
            'Money Left',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat.decimalPattern().format(moneyLeft)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              // UPDATED: Color now uses theme colors for consistency
              color: moneyLeft >= 0
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
    // Using a scrollable view in case the list is long
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
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
