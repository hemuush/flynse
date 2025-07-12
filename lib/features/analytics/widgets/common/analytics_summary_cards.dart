import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/features/analytics/widgets/common/color_helpers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A reusable card for displaying primary total figures (e.g., Net for Month/Year).
class TotalsCard extends StatelessWidget {
  final String title;
  final double amount;
  final double income;
  final double expense;
  final double saving;

  const TotalsCard({
    super.key,
    required this.title,
    required this.amount,
    required this.income,
    required this.expense,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                      locale: 'en_IN', symbol: '₹', decimalDigits: 2)
                  .format(amount),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: amount >= 0
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
              ),
            ),
            const Divider(height: 32),
            _buildSummaryRow(
                'Income', income, theme.colorScheme.tertiary, theme),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Expense', expense, theme.colorScheme.secondary, theme),
            const SizedBox(height: 12),
            // FIX: Corrected the order of arguments for the 'Saving' row.
            _buildSummaryRow(
                'Saving', saving, Colors.lightGreen.shade400, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, double value, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(
          NumberFormat.currency(
                  locale: 'en_IN', symbol: '₹', decimalDigits: 2)
              .format(value),
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// A reusable card for displaying a breakdown of data, typically with a PieChart.
class BreakdownCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> breakdown;

  const BreakdownCard({
    super.key,
    required this.title,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalExpense = breakdown.fold<double>(
        0, (sum, item) => sum + (item['total'] as num));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text('No expense data for this period.'),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 70,
                            sections: breakdown.asMap().entries.map((entry) {
                              final item = entry.value;
                              final percentage = totalExpense > 0
                                  ? (item['total'] / totalExpense) * 100
                                  : 0.0;
                              return PieChartSectionData(
                                value: item['total'] as double,
                                title: '${percentage.toStringAsFixed(0)}%',
                                color: getColorForCategory(
                                    context, item['category'] as String, entry.key),
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Expense',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                            Text(
                              NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 0)
                                  .format(totalExpense),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // FIX: Pass the BuildContext to the legend builder.
                  _buildLegend(context, theme, breakdown),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // FIX: Added BuildContext as a parameter to resolve scope issues.
  Widget _buildLegend(BuildContext context, ThemeData theme, List<Map<String, dynamic>> breakdown) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: breakdown.asMap().entries.map((entry) {
        final item = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: getColorForCategory(context, item['category'], entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(item['category']),
          ],
        );
      }).toList(),
    );
  }
}


/// A widget for displaying the detailed breakdown within an ExpansionTile in the Expense view.
class MonthlyExpenseDetails extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;
  final int year;
  final int month;

  const MonthlyExpenseDetails({
    super.key,
    required this.breakdown,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AnalyticsProvider>();
    final totalExpense =
        breakdown.fold<double>(0, (sum, item) => sum + (item['total'] as num));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: breakdown.asMap().entries.map((entry) {
                  final item = entry.value;
                  final percentage = totalExpense > 0
                      ? (item['total'] / totalExpense) * 100
                      : 0.0;
                  return PieChartSectionData(
                    value: item['total'] as double,
                    title: '${percentage.toStringAsFixed(0)}%',
                    color:
                        getColorForCategory(context, item['category'] as String, entry.key),
                    radius: 40,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("Breakdown",
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          ...breakdown.map((categoryData) {
            final categoryName = categoryData['category'] as String;
            final categoryTotal = categoryData['total'] as double;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(theme, categoryName, categoryTotal,
                    isCategory: true),
                _buildSubBreakdown(provider, theme, categoryName, month, year),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String title, double value,
      {bool isCategory = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isCategory
                ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                .format(value),
            style: isCategory
                ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSubBreakdown(AnalyticsProvider provider, ThemeData theme,
      String categoryName, int month, int year) {
    Future<List<Map<String, dynamic>>> future;
    String nameKey;

    switch (categoryName) {
      case 'Debt Repayment':
        future = provider.getDebtRepaymentBreakdownForMonth(year, month);
        nameKey = 'name';
        break;
      case 'Friends':
        future = provider.getFriendExpenseBreakdownForMonth(year, month);
        nameKey = 'name';
        break;
      default:
        future = provider.getSubCategoryBreakdownForMonth(year, month, categoryName);
        nameKey = 'sub_category';
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, subSnapshot) {
        if (!subSnapshot.hasData || subSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final subBreakdown = subSnapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
          child: Column(
            children: subBreakdown.map((sub) {
              return _buildDetailRow(theme, sub[nameKey], sub['total']);
            }).toList(),
          ),
        );
      },
    );
  }
}