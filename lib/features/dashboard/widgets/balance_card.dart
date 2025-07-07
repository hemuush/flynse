import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/features/dashboard/widgets/monthly_details_sheet.dart';
import 'package:flynse/shared/widgets/animated_count.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A central card on the dashboard that visualizes the monthly financial summary.
///
/// It includes:
/// - A prominent display of the cumulative balance up to the selected month.
/// - A bar chart showing the breakdown of income, expenses, and savings for the selected month.
/// - A tappable area to view more detailed monthly information.
class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  int? _touchedIndex;

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

    // --- UI ENHANCEMENT: Gradient Background ---
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surfaceContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
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
                  child: AnimatedCount(
                    begin: 0, // Start from 0 or a previous value
                    end: netBalance,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: netBalance >= 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                    ),
                    decimalDigits: 2,
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final amount = rod.toY;
              return BarTooltipItem(
                '₹${NumberFormat.decimalPattern('en_IN').format(amount)}',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
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
          _buildBarGroup(0, income, theme.colorScheme.tertiary, isTouched: _touchedIndex == 0),
          _buildBarGroup(1, expense, theme.colorScheme.secondary, isTouched: _touchedIndex == 1),
          _buildBarGroup(2, saving, Colors.lightGreen.shade400, isTouched: _touchedIndex == 2),
        ],
      ),
    );
  }

  /// Helper to create a single group of bars for the chart.
  BarChartGroupData _buildBarGroup(int x, double y, Color color, {bool isTouched = false}) {
    final double width = isTouched ? 28 : 24;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: width,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          borderSide: isTouched ? BorderSide(color: color.withOpacity(0.8), width: 2) : const BorderSide(color: Colors.transparent),
        ),
      ],
    );
  }
}
