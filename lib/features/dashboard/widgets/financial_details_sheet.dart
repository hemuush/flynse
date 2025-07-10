import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

enum SheetType { monthly, yearly }

class FinancialDetailsSheet extends StatelessWidget {
  final SheetType sheetType;

  const FinancialDetailsSheet({super.key, required this.sheetType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Consumer3<AppProvider, DashboardProvider, AnalyticsProvider>(
      builder: (context, appProvider, dashboardProvider, analyticsProvider, child) {
        final isMonthly = sheetType == SheetType.monthly;

        // Determine which data to use based on the sheet type
        final totals = isMonthly
            ? dashboardProvider.monthlyTotals
            : analyticsProvider.yearlyTotals;
        final breakdown = isMonthly
            ? dashboardProvider.monthlyCategoryBreakdown
            : analyticsProvider.yearlyCategoryBreakdown;

        final income = totals['Income'] ?? 0.0;
        final expense = totals['Expense'] ?? 0.0;
        final saving = totals['Saving'] ?? 0.0;
        final netValue = income - expense - saving;

        final monthName = DateFormat.MMMM().format(DateTime(0, appProvider.selectedMonth));
        final title = isMonthly
            ? 'Details for $monthName ${appProvider.selectedYear}'
            : 'Yearly Details for ${appProvider.selectedYear}';
        final netTitle = isMonthly ? 'Net for $monthName' : 'Net for the Year';
        final summaryTitle = isMonthly ? 'Summary for $monthName' : 'Summary';
        final breakdownTitle = isMonthly ? 'Expense Breakdown for $monthName' : 'Expense Breakdown';


        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildMoneyLeft(theme, netValue, netTitle),
                    if (isMonthly) ...[
                      const SizedBox(height: 16),
                       _buildMoneyLeft(theme, (dashboardProvider.cumulativeTotals['Income'] ?? 0.0) - (dashboardProvider.cumulativeTotals['Expense'] ?? 0.0) - (dashboardProvider.cumulativeTotals['Saving'] ?? 0.0), "Balance till End of Month"),
                    ],
                    const Divider(height: 32),
                    _buildSummarySection(theme, summaryTitle, income, expense, saving),
                    const Divider(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(breakdownTitle, style: theme.textTheme.titleMedium)
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // --- SCROLLABLE EXPENSE BREAKDOWN ---
              Flexible(
                child: _buildExpenseBreakdown(theme, breakdown),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 16, top: 24),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoneyLeft(ThemeData theme, double money, String title) {
    return Center(
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(money),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: money >= 0 ? theme.colorScheme.tertiary : theme.colorScheme.error,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, String title, double income, double expense, double saving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildSummaryRow(theme, 'Income', income, theme.colorScheme.tertiary),
        const SizedBox(height: 8),
        _buildSummaryRow(theme, 'Expense', expense, theme.colorScheme.secondary),
        const SizedBox(height: 8),
        _buildSummaryRow(theme, 'Saving', saving, Colors.lightGreen.shade400),
      ],
    );
  }
  
  Widget _buildSummaryRow(ThemeData theme, String label, double value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(value),
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// REFACTORED: This now builds a simple list of rows, removing the cards and expansion tiles.
  Widget _buildExpenseBreakdown(ThemeData theme, List<Map<String, dynamic>> categoryBreakdown) {
    if (categoryBreakdown.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No expense data for this period.')));
    }

    const double itemHeight = 44.0; 
    final int listSize = categoryBreakdown.length;
    
    // Calculate the container height: it's the height of up to 5 items.
    final double containerHeight = min(listSize, 5) * itemHeight;

    return SizedBox(
      height: containerHeight,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: listSize,
        itemBuilder: (context, index) {
          final categoryData = categoryBreakdown[index];
          final categoryName = categoryData['category'] as String;
          final categoryTotal = categoryData['total'] as double;
          
          return SizedBox(
            height: itemHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(categoryName, style: theme.textTheme.bodyLarge),
                Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(categoryTotal),
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}