import 'package:flutter/material.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/features/analytics/widgets/common/analytics_summary_cards.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A widget that provides a detailed, expandable list of expenses,
/// broken down by month and category for a selected year.
class ExpenseAnalyticsView extends StatefulWidget {
  final int initialSelectedYear;

  const ExpenseAnalyticsView({super.key, required this.initialSelectedYear});

  @override
  State<ExpenseAnalyticsView> createState() => _ExpenseAnalyticsViewState();
}

class _ExpenseAnalyticsViewState extends State<ExpenseAnalyticsView> {
  late int _selectedAnalyticsYear;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedAnalyticsYear = widget.initialSelectedYear;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final theme = Theme.of(context);

    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final monthlyTotals = provider.monthlyExpenseTotals;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<int>(
                value: _selectedAnalyticsYear,
                items: appProvider.availableYears
                    .map((year) =>
                        DropdownMenuItem(value: year, child: Text("Year $year")))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAnalyticsYear = value;
                    });
                    provider.fetchAnalyticsData(value);
                  }
                },
                decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        borderSide: BorderSide.none)),
              ),
            ),
            Expanded(
              child: monthlyTotals.isEmpty
                  ? const Center(child: Text('No expense data for this year.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: monthlyTotals.length,
                      itemBuilder: (context, index) {
                        final monthData = monthlyTotals[index];
                        final monthIndex = int.parse(monthData['month']) - 1;
                        final monthName = _monthNames[monthIndex];
                        final total = monthData['total'] as double;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          clipBehavior: Clip.antiAlias,
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainer,
                          child: ExpansionTile(
                            title: Text(monthName,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 0)
                                  .format(total),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary),
                            ),
                            children: [
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: provider.getMonthlyCategoryBreakdown(
                                    _selectedAnalyticsYear, monthIndex + 1),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child:
                                          Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const ListTile(
                                        title:
                                            Text('No expenses for this month.'));
                                  }
                                  final breakdown = snapshot.data!;
                                  return MonthlyExpenseDetails(
                                    breakdown: breakdown,
                                    year: _selectedAnalyticsYear,
                                    month: monthIndex + 1,
                                  );
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
