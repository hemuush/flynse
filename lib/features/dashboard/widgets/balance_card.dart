import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/features/dashboard/widgets/monthly_details_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A central card on the dashboard that visualizes the monthly financial summary.
///
/// It includes:
/// - A prominent display of the cumulative balance up to the selected month.
/// - A bar chart showing the breakdown of income, expenses, and savings for the selected month.
/// - A tappable area to view more detailed monthly information.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();
    final appProvider = context.watch<AppProvider>();

    // Monthly totals for the bar chart
    final income = provider.monthlyTotals['Income'] ?? 0.0;
    final expense = provider.monthlyTotals['Expense'] ?? 0.0;
    final saving = provider.monthlyTotals['Saving'] ?? 0.0;

    // Cumulative totals for the main balance display
    final cumulativeIncome = provider.cumulativeTotals['Income'] ?? 0.0;
    final cumulativeExpense = provider.cumulativeTotals['Expense'] ?? 0.0;
    final cumulativeSaving = provider.cumulativeTotals['Saving'] ?? 0.0;
    final netBalance = cumulativeIncome - cumulativeExpense - cumulativeSaving;
    
    final monthName =
        DateFormat.MMMM().format(DateTime(0, appProvider.selectedMonth));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Show detailed monthly sheet on tap.
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const MonthlyDetailsSheet(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance till $monthName',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // --- Net Balance Display ---
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₹${NumberFormat.decimalPattern('en_IN').format(netBalance)}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // --- Bar Chart Visual ---
              SizedBox(
                height: 120,
                child: _buildBarChart(context, income, expense, saving),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bar chart using the `fl_chart` package.
  Widget _buildBarChart(
      BuildContext context, double income, double expense, double saving) {
    final theme = Theme.of(context);
    final double maxValue =
        [income, expense, saving, 1000.0].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2, // Add some padding to the top of the chart
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          // Hide all titles for a cleaner look.
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // Define the bottom titles for each bar.
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text;
                IconData icon;
                Color color;
                switch (value.toInt()) {
                  case 0:
                    text = 'Income';
                    icon = Icons.arrow_downward;
                    color = theme.colorScheme.tertiary;
                    break;
                  case 1:
                    text = 'Expense';
                    icon = Icons.arrow_upward;
                    color = theme.colorScheme.secondary;
                    break;
                  case 2:
                    text = 'Saving';
                    icon = Icons.savings;
                    color = Colors.lightGreen.shade400;
                    break;
                  default:
                    return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Column(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(height: 2),
                      Text(text,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false), // No border
        gridData: const FlGridData(show: false), // No grid lines
        barGroups: [
          _buildBarGroup(0, income, theme.colorScheme.tertiary),
          _buildBarGroup(1, expense, theme.colorScheme.secondary),
          _buildBarGroup(2, saving, Colors.lightGreen.shade400),
        ],
      ),
    );
  }

  /// Helper to create a single group of bars for the chart.
  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}