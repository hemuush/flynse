import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/features/analytics/widgets/common/analytics_charts.dart';
import 'package:flynse/features/analytics/widgets/common/analytics_summary_cards.dart';
import 'package:provider/provider.dart';

/// A widget that displays the analytics for an entire year.
class YearlyAnalyticsView extends StatelessWidget {
  final int selectedYear;

  const YearlyAnalyticsView({
    super.key,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final totals = provider.yearlyTotals;
        final breakdown = provider.yearlyCategoryBreakdown;
        final moneyLeft = (totals['Income'] ?? 0) -
            (totals['Expense'] ?? 0) -
            (totals['Saving'] ?? 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Text(
              '$selectedYear Summary',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TotalsCard(
              title: 'Net for the Year',
              amount: moneyLeft,
              income: totals['Income'] ?? 0.0,
              expense: totals['Expense'] ?? 0.0,
              saving: totals['Saving'] ?? 0.0,
            ),
            const SizedBox(height: 24),
            YearlyTrendChart(yearlyBreakdown: provider.yearlyMonthlyBreakdown),
            const SizedBox(height: 24),
            BreakdownCard(
              title: 'Yearly Expense Breakdown',
              breakdown: breakdown,
            ),
          ],
        );
      },
    );
  }
}
