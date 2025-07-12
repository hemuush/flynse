import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/features/analytics/widgets/common/analytics_summary_cards.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A widget that displays the analytics for a single selected month.
class MonthlyAnalyticsView extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;

  const MonthlyAnalyticsView({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final totals = provider.monthlyTotals;
        final breakdown = provider.monthlyCategoryBreakdown;
        final moneyLeft = (totals['Income'] ?? 0) -
            (totals['Expense'] ?? 0) -
            (totals['Saving'] ?? 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Text(
              '${DateFormat.MMMM().format(DateTime(0, selectedMonth))} $selectedYear',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TotalsCard(
              title: 'Net for the Month',
              amount: moneyLeft,
              income: totals['Income'] ?? 0.0,
              expense: totals['Expense'] ?? 0.0,
              saving: totals['Saving'] ?? 0.0,
            ),
            const SizedBox(height: 24),
            BreakdownCard(
              title: 'Monthly Expense Breakdown',
              breakdown: breakdown,
            ),
          ],
        );
      },
    );
  }
}
